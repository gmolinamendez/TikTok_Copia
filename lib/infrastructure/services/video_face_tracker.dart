import 'dart:io';

import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toktok/domain/entities/face_frame.dart';
import 'package:toktok/infrastructure/services/face_detector_service.dart';


// Recorre el video sacando un cuadro cada [stepMs] y busca la cara en cada uno.
// El resultado es la lista de posiciones que usa el filtro para seguir la cara al reproducir.
class VideoFaceTracker {

  static const int stepMs = 250;
  static const int maxDurationMs = 60 * 1000;

  final FaceDetectorService _faceDetector = FaceDetectorService();

  Future<List<FaceFrame>> track({
    required String videoPath,
    required int durationMs,
    void Function( double progress )? onProgress,
  }) async {

    final tempDir = await getTemporaryDirectory();
    final framesDir = await Directory( '${ tempDir.path }/face_frames' ).create( recursive: true );
    final totalMs = durationMs.clamp( 0, maxDurationMs );
    final track = <FaceFrame>[];

    for ( var timeMs = 0; timeMs <= totalMs; timeMs += stepMs ) {
      try {
        final frame = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: '${ framesDir.path }/frame_$timeMs.jpg',
          imageFormat: ImageFormat.JPEG,
          maxHeight: 480,
          timeMs: timeMs,
          quality: 70,
        );
        final face = await _faceDetector.detectInFile( frame.path );
        if ( face != null ) track.add( face.withTime( timeMs ) );
        await File( frame.path ).delete();
      } catch (e) {
        // Si un cuadro no se puede leer (por ejemplo, el final exacto del video), lo saltamos
      }

      onProgress?.call( totalMs == 0 ? 1 : timeMs / totalMs );
    }

    return track;
  }

  Future<void> dispose() => _faceDetector.dispose();

}
