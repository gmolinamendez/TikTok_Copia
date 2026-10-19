import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:toktok/domain/entities/face_frame.dart';


// Usa ML Kit (solo Android / iOS) para encontrar la cara más grande de una imagen
// y devolver la posición de ojos, nariz y boca en coordenadas 0..1.
class FaceDetectorService {

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  Future<FaceFrame?> detectInFile( String path ) async {
    final bytes = await File( path ).readAsBytes();
    final image = await decodeImageFromList( bytes );
    final size = Size( image.width.toDouble(), image.height.toDouble() );
    image.dispose();

    final faces = await _detector.processImage( InputImage.fromFilePath( path ) );
    return _toFaceFrame( faces, size );
  }

  // Para el video en vivo de la cámara. Si todavía está procesando el cuadro anterior,
  // se salta este (regresa null) para no trabar la cámara.
  Future<FaceFrame?> detectInCameraImage( CameraImage image, CameraDescription camera ) async {
    if ( _isBusy ) return null;
    _isBusy = true;

    try {
      final rotation = InputImageRotationValue.fromRawValue( camera.sensorOrientation )
        ?? InputImageRotation.rotation0deg;
      final format = InputImageFormatValue.fromRawValue( image.format.raw );
      if ( format == null || image.planes.isEmpty ) return null;

      final inputImage = InputImage.fromBytes(
        bytes: _concatenatePlanes( image.planes ),
        metadata: InputImageMetadata(
          size: Size( image.width.toDouble(), image.height.toDouble() ),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      // ML Kit regresa coordenadas en la imagen ya girada (vertical)
      final isRotated = rotation == InputImageRotation.rotation90deg
        || rotation == InputImageRotation.rotation270deg;
      final uprightSize = isRotated
        ? Size( image.height.toDouble(), image.width.toDouble() )
        : Size( image.width.toDouble(), image.height.toDouble() );

      final faces = await _detector.processImage( inputImage );
      return _toFaceFrame( faces, uprightSize );
    } catch (e) {
      debugPrint('Error detectando cara: $e');
      return null;
    } finally {
      _isBusy = false;
    }
  }

  Uint8List _concatenatePlanes( List<Plane> planes ) {
    final buffer = WriteBuffer();
    for ( final plane in planes ) {
      buffer.putUint8List( plane.bytes );
    }
    return buffer.done().buffer.asUint8List();
  }

  FaceFrame? _toFaceFrame( List<Face> faces, Size size ) {
    if ( faces.isEmpty || size.isEmpty ) return null;

    final face = faces.reduce( (a, b) =>
      a.boundingBox.width * a.boundingBox.height >= b.boundingBox.width * b.boundingBox.height ? a : b );
    final box = face.boundingBox;

    Offset normalize( Offset p ) => Offset( p.dx / size.width, p.dy / size.height );

    Offset landmark( FaceLandmarkType type, Offset fallback ) {
      final position = face.landmarks[type]?.position;
      return position == null
        ? fallback
        : Offset( position.x.toDouble(), position.y.toDouble() );
    }

    // Si ML Kit no encuentra algún punto, se calcula aproximado con el rectángulo de la cara
    var eyeA = landmark( FaceLandmarkType.leftEye, Offset( box.left + box.width * 0.68, box.top + box.height * 0.4 ) );
    var eyeB = landmark( FaceLandmarkType.rightEye, Offset( box.left + box.width * 0.32, box.top + box.height * 0.4 ) );
    // leftEye = el que se ve a la izquierda de la imagen
    if ( eyeA.dx > eyeB.dx ) {
      final temp = eyeA;
      eyeA = eyeB;
      eyeB = temp;
    }
    final nose = landmark( FaceLandmarkType.noseBase, Offset( box.center.dx, box.top + box.height * 0.62 ) );
    final mouth = landmark( FaceLandmarkType.bottomMouth, Offset( box.center.dx, box.top + box.height * 0.85 ) );

    return FaceFrame(
      leftEye: normalize( eyeA ),
      rightEye: normalize( eyeB ),
      nose: normalize( nose ),
      mouth: normalize( mouth ),
      box: Rect.fromLTRB(
        box.left / size.width, box.top / size.height,
        box.right / size.width, box.bottom / size.height,
      ),
    );
  }

  Future<void> dispose() => _detector.close();

}
