import 'package:flutter/material.dart';
import 'package:toktok/presentation/widgets/video/fullscreen_player.dart';
import 'package:toktok/presentation/widgets/video/video_background.dart';


// Publicaciones de foto. El filtro ya viene "pegado" en la imagen al publicarla.
class FullScreenImage extends StatelessWidget {

  final String imageUrl;
  final String caption;

  const FullScreenImage({ super.key, required this.imageUrl, required this.caption });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [

        Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center( child: CircularProgressIndicator( strokeWidth: 2 ) ),
          errorBuilder: (context, error, stackTrace) =>
            const Center( child: Icon( Icons.broken_image_outlined, size: 48 ) ),
        ),

        VideoBackground( stops: const [0.8, 1.0] ),

        Positioned(
          bottom: 50,
          left: 20,
          child: VideoCaption( caption: caption ),
        ),

      ],
    );
  }
}
