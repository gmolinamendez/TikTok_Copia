import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/presentation/filters/face_filter.dart';
import 'package:toktok/presentation/widgets/shared/video_buttons.dart';
import 'package:toktok/presentation/widgets/video/fullscreen_image.dart';
import 'package:toktok/presentation/widgets/video/fullscreen_player.dart';


class VideoScrollableView extends StatelessWidget {

  final List<VideoPost> videos;

  const VideoScrollableView({
    super.key,
    required this.videos
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final VideoPost videoPost = videos[index];

        return Stack(
          children: [
            // Video (o foto) + gradiente
            SizedBox.expand(
              child: videoPost.isImage
                ? FullScreenImage(
                    imageUrl: videoPost.videoUrl,
                    caption: videoPost.caption,
                  )
                : FullScreenPlayer(
                    key: ValueKey( videoPost.id ),
                    caption: videoPost.caption,
                    videoUrl: videoPost.videoUrl,
                    filter: FaceFilter.fromId( videoPost.filterId ),
                    faceTrack: videoPost.faceTrack,
                  )
            ),

            // Botones
            Positioned(
              bottom: 40,
              right: 20,
              child: VideoButtons(video: videoPost)
            ),

          ],
        );

      },
    );
  }
}
