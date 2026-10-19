import 'dart:io';

import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/face_frame.dart';
import 'package:toktok/infrastructure/services/video_face_tracker.dart';
import 'package:toktok/presentation/filters/face_filter.dart';
import 'package:toktok/presentation/screens/create/publish_screen.dart';
import 'package:toktok/presentation/widgets/video/fullscreen_player.dart';
import 'package:video_player/video_player.dart';


// Analiza el video para saber dónde está la cara en cada momento
// y deja escoger el filtro que la va a seguir.
class VideoEditorScreen extends StatefulWidget {

  final String videoPath;
  final FaceFilter initialFilter;

  const VideoEditorScreen({
    super.key,
    required this.videoPath,
    this.initialFilter = FaceFilter.glassesAndMustache,
  });

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {

  final VideoFaceTracker _tracker = VideoFaceTracker();

  late FaceFilter filter = widget.initialFilter;
  List<FaceFrame>? faceTrack;
  double progress = 0;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    try {
      final probe = VideoPlayerController.file( File( widget.videoPath ) );
      await probe.initialize();
      final durationMs = probe.value.duration.inMilliseconds;
      await probe.dispose();

      final track = await _tracker.track(
        videoPath: widget.videoPath,
        durationMs: durationMs,
        onProgress: (value) {
          if ( mounted ) setState(() => progress = value );
        },
      );
      if ( mounted ) setState(() => faceTrack = track );
    } catch (e) {
      if ( mounted ) setState(() => errorMessage = 'No se pudo analizar el video: $e' );
    }
  }

  Future<void> _next() async {
    final track = faceTrack ?? [];
    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute( builder: (_) => PublishScreen.video(
        videoPath: widget.videoPath,
        filter: track.isEmpty ? FaceFilter.none : filter,
        faceTrack: track,
      )),
    );
    if ( published == true && mounted ) Navigator.of(context).pop( true );
  }

  @override
  void dispose() {
    _tracker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final faceTrack = this.faceTrack;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Editar video'),
        actions: [
          TextButton(
            onPressed: faceTrack == null && errorMessage == null ? null : _next,
            child: const Text('Siguiente'),
          ),
        ],
      ),
      body: Column(
        children: [

          Expanded(
            child: errorMessage != null
              ? Center( child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text( errorMessage!, textAlign: TextAlign.center ),
                ))
              : faceTrack == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Buscando tu cara en el video...'),
                          const SizedBox( height: 16 ),
                          LinearProgressIndicator( value: progress ),
                          const SizedBox( height: 8 ),
                          Text( '${ (progress * 100).round() }%' ),
                        ],
                      ),
                    ),
                  )
                : FullScreenPlayer(
                    videoUrl: widget.videoPath,
                    caption: '',
                    filter: filter,
                    faceTrack: faceTrack,
                  ),
          ),

          if ( faceTrack != null && faceTrack.isEmpty )
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'No encontramos ninguna cara en el video, así que se publicará sin filtro.',
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
