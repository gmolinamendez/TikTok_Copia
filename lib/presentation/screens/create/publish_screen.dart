import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/domain/entities/face_frame.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/infrastructure/datasources/firestore_video_posts_datasource.dart';
import 'package:toktok/infrastructure/services/cloudinary_service.dart';
import 'package:toktok/presentation/filters/face_filter.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/widgets/video/fullscreen_player.dart';


// Último paso: escribir el título, subir el archivo a Cloudinary y guardar la publicación en Firestore.
class PublishScreen extends StatefulWidget {

  final Uint8List? imageBytes;
  final String? videoPath;
  final FaceFilter filter;
  final List<FaceFrame> faceTrack;

  const PublishScreen.image({ super.key, required Uint8List this.imageBytes, this.filter = FaceFilter.none })
    : videoPath = null,
      faceTrack = const [];

  const PublishScreen.video({
    super.key,
    required String this.videoPath,
    this.filter = FaceFilter.none,
    this.faceTrack = const [],
  }) : imageBytes = null;

  bool get isVideo => videoPath != null;

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {

  final _titleController = TextEditingController();
  bool isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    if ( title.isEmpty ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar( content: Text('Escribe un título para tu publicación') ) );
      return;
    }

    final user = context.read<AuthProvider>().user!;
    setState(() => isUploading = true );

    try {
      final bytes = widget.isVideo
        ? await File( widget.videoPath! ).readAsBytes()
        : widget.imageBytes!;

      final url = await CloudinaryService().upload(
        bytes: bytes,
        fileName: widget.isVideo ? 'video.mp4' : 'foto.png',
        isVideo: widget.isVideo,
      );

      await FirestoreVideoPostsDatasource().createPost(
        title: title,
        mediaUrl: url,
        mediaType: widget.isVideo ? MediaType.video : MediaType.image,
        userId: user.uid,
        userEmail: user.email,
        // En las fotos el filtro ya está dibujado en la imagen; en los videos se dibuja al reproducir
        filterId: widget.isVideo ? widget.filter.name : 'none',
        faceTrack: widget.isVideo ? widget.faceTrack : const [],
      );

      if ( mounted ) Navigator.of(context).pop( true );
    } catch (e) {
      if ( !mounted ) return;
      setState(() => isUploading = false );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar( content: Text('No se pudo publicar: $e') ) );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: const Text('Publicar') ),
      body: SafeArea(
        child: Column(
          children: [

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.isVideo
                    ? FullScreenPlayer(
                        videoUrl: widget.videoPath!,
                        caption: '',
                        filter: widget.filter,
                        faceTrack: widget.faceTrack,
                      )
                    : Image.memory( widget.imageBytes!, fit: BoxFit.contain ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric( horizontal: 16 ),
              child: TextField(
                controller: _titleController,
                enabled: !isUploading,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: '¿Qué está pasando?',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB( 16, 0, 16, 16 ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isUploading ? null : _publish,
                  icon: isUploading
                    ? const SizedBox( width: 18, height: 18, child: CircularProgressIndicator( strokeWidth: 2 ) )
                    : const Icon( Icons.cloud_upload_outlined ),
                  label: Text( isUploading ? 'Subiendo...' : 'Publicar' ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
