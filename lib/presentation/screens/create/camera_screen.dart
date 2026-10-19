import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/face_frame.dart';
import 'package:toktok/infrastructure/services/face_detector_service.dart';
import 'package:toktok/presentation/filters/face_filter.dart';
import 'package:toktok/presentation/screens/create/photo_editor_screen.dart';
import 'package:toktok/presentation/screens/create/video_editor_screen.dart';


class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {

  static const maxRecordingSeconds = 30;

  final FaceDetectorService _faceDetector = FaceDetectorService();

  List<CameraDescription> cameras = [];
  CameraController? controller;
  String? errorMessage;

  FaceFilter filter = FaceFilter.glassesAndMustache;
  FaceFrame? face;
  bool isVideoMode = false;
  bool isRecording = false;
  bool isBusy = false;
  int recordedSeconds = 0;
  Timer? recordingTimer;

  @override
  void initState() {
    super.initState();
    _setupCameras();
  }

  Future<void> _setupCameras() async {
    try {
      cameras = await availableCameras();
      if ( cameras.isEmpty ) {
        setState(() => errorMessage = 'No se encontró ninguna cámara');
        return;
      }
      // Empezamos con la cámara frontal (selfie) si existe
      final front = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      await _startCamera( front );
    } on CameraException catch (e) {
      setState(() => errorMessage = 'No se pudo abrir la cámara: ${ e.description ?? e.code }');
    }
  }

  Future<void> _startCamera( CameraDescription camera ) async {
    final oldController = controller;
    setState(() {
      controller = null;
      face = null;
    });
    await oldController?.dispose();

    final newController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await newController.initialize();
      if ( !mounted ) {
        await newController.dispose();
        return;
      }
      setState(() => controller = newController );
      await _startFaceDetection();
    } on CameraException catch (e) {
      setState(() => errorMessage = 'No se pudo abrir la cámara: ${ e.description ?? e.code }');
    }
  }

  CameraDescription get _camera => controller!.description;
  bool get _isFrontCamera => controller?.description.lensDirection == CameraLensDirection.front;

  Future<void> _startFaceDetection() async {
    final controller = this.controller;
    if ( controller == null || controller.value.isStreamingImages ) return;
    await controller.startImageStream( _onCameraImage );
  }

  Future<void> _stopFaceDetection() async {
    final controller = this.controller;
    if ( controller == null || !controller.value.isStreamingImages ) return;
    await controller.stopImageStream();
  }

  Future<void> _onCameraImage( CameraImage image ) async {
    if ( filter == FaceFilter.none ) return;
    final detected = await _faceDetector.detectInCameraImage( image, _camera );
    // null también puede ser "estaba ocupado"; solo borramos la cara si de verdad no hay
    if ( mounted && ( detected != null || !_faceDetector.isBusy ) ) {
      setState(() => face = detected );
    }
  }

  Future<void> _switchCamera() async {
    if ( cameras.length < 2 || isRecording ) return;
    final next = cameras.firstWhere( (camera) => camera != _camera, orElse: () => _camera );
    await _startCamera( next );
  }

  Future<void> _onShutterPressed() async {
    final controller = this.controller;
    if ( controller == null || isBusy ) return;

    if ( !isVideoMode ) return _takePicture();
    isRecording ? await _stopRecording() : await _startRecording();
  }

  Future<void> _takePicture() async {
    setState(() => isBusy = true );
    try {
      await _stopFaceDetection();
      final photo = await controller!.takePicture();
      if ( !mounted ) return;

      final published = await Navigator.of(context).push<bool>(
        MaterialPageRoute( builder: (_) => PhotoEditorScreen( imagePath: photo.path, initialFilter: filter ) ),
      );
      if ( published == true && mounted ) return Navigator.of(context).pop( true );
    } on CameraException catch (e) {
      _showError( 'No se pudo tomar la foto: ${ e.description ?? e.code }' );
    } finally {
      if ( mounted ) {
        setState(() => isBusy = false );
        await _startFaceDetection();
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      await _stopFaceDetection();
      // Mientras graba seguimos detectando la cara para ver el filtro en vivo
      await controller!.startVideoRecording( onAvailable: _onCameraImage );

      setState(() {
        isRecording = true;
        recordedSeconds = 0;
      });
      recordingTimer = Timer.periodic( const Duration( seconds: 1 ), (timer) {
        setState(() => recordedSeconds++ );
        if ( recordedSeconds >= maxRecordingSeconds ) _stopRecording();
      });
    } on CameraException catch (e) {
      _showError( 'No se pudo grabar: ${ e.description ?? e.code }' );
      await _startFaceDetection();
    }
  }

  Future<void> _stopRecording() async {
    if ( !isRecording ) return;
    recordingTimer?.cancel();
    setState(() {
      isRecording = false;
      isBusy = true;
    });

    try {
      final video = await controller!.stopVideoRecording();
      if ( !mounted ) return;

      final published = await Navigator.of(context).push<bool>(
        MaterialPageRoute( builder: (_) => VideoEditorScreen( videoPath: video.path, initialFilter: filter ) ),
      );
      if ( published == true && mounted ) return Navigator.of(context).pop( true );
    } on CameraException catch (e) {
      _showError( 'No se pudo guardar el video: ${ e.description ?? e.code }' );
    } finally {
      if ( mounted ) {
        setState(() => isBusy = false );
        await _startFaceDetection();
      }
    }
  }

  void _showError( String message ) {
    if ( !mounted ) return;
    ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text( message ) ) );
  }

  @override
  void dispose() {
    recordingTimer?.cancel();
    controller?.dispose();
    _faceDetector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final controller = this.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [

            // Vista de la cámara + filtro
            if ( errorMessage != null )
              Center( child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text( errorMessage!, textAlign: TextAlign.center ),
              ))
            else if ( controller == null || !controller.value.isInitialized )
              const Center( child: CircularProgressIndicator( strokeWidth: 2 ) )
            else
              Center(
                child: AspectRatio(
                  // En vertical el preview es "alto": se invierte la proporción del sensor
                  aspectRatio: 1 / controller.value.aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview( controller ),
                      CustomPaint(
                        painter: FaceFilterPainter(
                          filter: filter,
                          // La cámara frontal se ve como espejo
                          face: _isFrontCamera ? face?.mirrored() : face,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Barra de arriba
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    onPressed: isRecording ? null : () => Navigator.of(context).pop(),
                    icon: const Icon( Icons.close, color: Colors.white ),
                  ),
                  const Spacer(),
                  if ( isRecording )
                    Container(
                      padding: const EdgeInsets.symmetric( horizontal: 10, vertical: 4 ),
                      decoration: BoxDecoration( color: Colors.red, borderRadius: BorderRadius.circular(12) ),
                      child: Text( '● 0:${ recordedSeconds.toString().padLeft(2, '0') } / 0:$maxRecordingSeconds' ),
                    ),
                  const Spacer(),
                  IconButton(
                    onPressed: cameras.length < 2 || isRecording ? null : _switchCamera,
                    icon: const Icon( Icons.cameraswitch_outlined, color: Colors.white ),
                  ),
                ],
              ),
            ),

            // Controles de abajo
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Column(
                children: [

                  if ( filter != FaceFilter.none && face == null && controller != null )
                    const Padding(
                      padding: EdgeInsets.only( bottom: 8 ),
                      child: Text( 'Pon tu cara frente a la cámara', style: TextStyle( color: Colors.white70 ) ),
                    ),

                  FilterSelector(
                    selected: filter,
                    onSelected: (newFilter) => setState(() => filter = newFilter ),
                  ),
                  const SizedBox( height: 12 ),

                  // Botón para tomar foto / grabar
                  GestureDetector(
                    onTap: _onShutterPressed,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all( color: Colors.white, width: 4 ),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: isBusy
                        ? const CircularProgressIndicator( strokeWidth: 2 )
                        : AnimatedContainer(
                            duration: const Duration( milliseconds: 200 ),
                            decoration: BoxDecoration(
                              color: isVideoMode ? Colors.red : Colors.white,
                              shape: isRecording ? BoxShape.rectangle : BoxShape.circle,
                              borderRadius: isRecording ? BorderRadius.circular(8) : null,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox( height: 12 ),

                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment( value: false, label: Text('Foto'), icon: Icon( Icons.photo_camera_outlined ) ),
                      ButtonSegment( value: true, label: Text('Video'), icon: Icon( Icons.videocam_outlined ) ),
                    ],
                    selected: { isVideoMode },
                    onSelectionChanged: isRecording
                      ? null
                      : (selection) => setState(() => isVideoMode = selection.first ),
                  ),

                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}
