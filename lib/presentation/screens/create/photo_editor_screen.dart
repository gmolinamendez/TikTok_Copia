import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:toktok/domain/entities/face_frame.dart';
import 'package:toktok/infrastructure/services/face_detector_service.dart';
import 'package:toktok/presentation/filters/face_filter.dart';
import 'package:toktok/presentation/screens/create/publish_screen.dart';


class PhotoEditorScreen extends StatefulWidget {

  final String imagePath;
  final FaceFilter initialFilter;

  const PhotoEditorScreen({
    super.key,
    required this.imagePath,
    this.initialFilter = FaceFilter.glassesAndMustache,
  });

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {

  final _boundaryKey = GlobalKey();
  final FaceDetectorService _faceDetector = FaceDetectorService();

  late FaceFilter filter = widget.initialFilter;
  Size? imageSize;
  FaceFrame? face;
  bool isAnalyzing = true;
  bool isExporting = false;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    final bytes = await File( widget.imagePath ).readAsBytes();
    final image = await decodeImageFromList( bytes );
    final size = Size( image.width.toDouble(), image.height.toDouble() );
    image.dispose();

    FaceFrame? detected;
    try {
      detected = await _faceDetector.detectInFile( widget.imagePath );
    } catch (e) {
      debugPrint('Error detectando cara: $e');
    }

    if ( !mounted ) return;
    setState(() {
      imageSize = size;
      face = detected;
      isAnalyzing = false;
    });
  }

  // Convierte lo que se ve (foto + filtro) en una sola imagen PNG
  Future<void> _next() async {
    setState(() => isExporting = true );

    final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final targetWidth = min( imageSize!.width, 1080.0 );
    final image = await boundary.toImage( pixelRatio: targetWidth / boundary.size.width );
    final data = await image.toByteData( format: ui.ImageByteFormat.png );
    image.dispose();

    if ( !mounted ) return;
    setState(() => isExporting = false );

    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute( builder: (_) => PublishScreen.image(
        imageBytes: data!.buffer.asUint8List(),
        filter: face == null ? FaceFilter.none : filter,
      )),
    );
    if ( published == true && mounted ) Navigator.of(context).pop( true );
  }

  @override
  void dispose() {
    _faceDetector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final imageSize = this.imageSize;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Editar foto'),
        actions: [
          TextButton(
            onPressed: isAnalyzing || isExporting ? null : _next,
            child: const Text('Siguiente'),
          ),
        ],
      ),
      body: Column(
        children: [

          Expanded(
            child: imageSize == null
              ? const Center( child: CircularProgressIndicator( strokeWidth: 2 ) )
              : Center(
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: AspectRatio(
                      aspectRatio: imageSize.width / imageSize.height,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file( File( widget.imagePath ), fit: BoxFit.fill ),
                          CustomPaint( painter: FaceFilterPainter( filter: filter, face: face ) ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),

          if ( !isAnalyzing && face == null )
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'No encontramos ninguna cara en la foto, así que se publicará sin filtro.',
                textAlign: TextAlign.center,
                style: TextStyle( color: Colors.white70 ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric( vertical: 12 ),
            child: FilterSelector(
              selected: filter,
              onSelected: (newFilter) => setState(() => filter = newFilter ),
            ),
          ),

        ],
      ),
    );
  }
}
