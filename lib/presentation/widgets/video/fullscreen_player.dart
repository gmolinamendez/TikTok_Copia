import 'dart:io';

import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/face_frame.dart';
import 'package:toktok/presentation/filters/face_filter.dart';
import 'package:toktok/presentation/widgets/video/video_background.dart';
import 'package:video_player/video_player.dart';

class FullScreenPlayer extends StatefulWidget {

  final String videoUrl;
  final String caption;
  final FaceFilter filter;
  final List<FaceFrame> faceTrack;

  const FullScreenPlayer({
    super.key,
    required this.videoUrl,
    required this.caption,
    this.filter = FaceFilter.none,
    this.faceTrack = const [],
  });

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {

  late VideoPlayerController controller;
  late Future<void> initializeVideo;

  @override
  void initState() {
    super.initState();

    // URL de internet, video del proyecto (assets) o archivo del celular (vista previa antes de publicar)
    if ( widget.videoUrl.startsWith('http') ) {
      controller = VideoPlayerController.networkUrl( Uri.parse( widget.videoUrl ) );
    } else if ( widget.videoUrl.startsWith('assets/') ) {
      controller = VideoPlayerController.asset( widget.videoUrl );
    } else {
      controller = VideoPlayerController.file( File( widget.videoUrl ) );
    }

    initializeVideo = controller.initialize().then((_) {
      controller
        ..setVolume(0)
        ..setLooping(true)
        ..play();
    });

  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: initializeVideo,
      builder: (context, snapshot) {
        if ( snapshot.connectionState != ConnectionState.done ){
          return const Center( child: CircularProgressIndicator( strokeWidth: 2 ));
        }

        return GestureDetector(
          onTap: () {
            if ( controller.value.isPlaying ) {
              controller.pause();
              return;
            }
            controller.play();

          },
          child: Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [

                  VideoPlayer(controller),

                  // Filtro que sigue la cara según el segundo del video
                  if ( widget.filter != FaceFilter.none && widget.faceTrack.isNotEmpty )
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: controller,
                      builder: (context, value, _) => CustomPaint(
                        painter: FaceFilterPainter(
                          filter: widget.filter,
                          face: FaceFrame.atTime( widget.faceTrack, value.position.inMilliseconds ),
                        ),
                      ),
                    ),

                  // Gradiente
                  VideoBackground(
                    stops: const [0.8,1.0],
                  ),

                  // Texto
                  Positioned(
                    bottom: 50,
                    left: 20,
                    child: VideoCaption( caption: widget.caption )
                  ),


                ],
              ),
            ),
          ),
        );

      },
    );
  }
}


class VideoCaption extends StatelessWidget {

  final String caption;


  const VideoCaption({ super.key, required this.caption });

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return SizedBox(
      width: size.width * 0.6,
      child: Text( caption, maxLines: 2, style: titleStyle ),
    );
  }
}
