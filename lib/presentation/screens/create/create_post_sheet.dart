import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toktok/presentation/screens/create/camera_screen.dart';
import 'package:toktok/presentation/screens/create/photo_editor_screen.dart';
import 'package:toktok/presentation/screens/create/video_editor_screen.dart';


// Menú para escoger de dónde viene la publicación. Regresa true si se publicó algo.
Future<bool?> showCreatePostSheet( BuildContext context ) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          if ( kIsWeb )
            const Padding(
              padding: EdgeInsets.symmetric( horizontal: 24, vertical: 8 ),
              child: Text(
                'La cámara y los filtros funcionan en la app de Android. '
                'Aquí en la web solo puedes ver los videos y dar like.',
                textAlign: TextAlign.center,
              ),
            ),

          ListTile(
            enabled: !kIsWeb,
            leading: const Icon( Icons.camera_alt_outlined ),
            title: const Text('Cámara con filtros'),
            subtitle: const Text('Toma una foto o graba un video'),
            onTap: () => _openCamera( sheetContext ),
          ),
          ListTile(
            enabled: !kIsWeb,
            leading: const Icon( Icons.photo_outlined ),
            title: const Text('Foto de la galería'),
            onTap: () => _pickFromGallery( sheetContext, isVideo: false ),
          ),
          ListTile(
            enabled: !kIsWeb,
            leading: const Icon( Icons.video_library_outlined ),
            title: const Text('Video de la galería'),
            onTap: () => _pickFromGallery( sheetContext, isVideo: true ),
          ),
          const SizedBox( height: 8 ),

        ],
      ),
    ),
  );
}

Future<void> _openCamera( BuildContext sheetContext ) async {
  final published = await Navigator.of( sheetContext ).push<bool>(
    MaterialPageRoute( builder: (_) => const CameraScreen() ),
  );
  if ( sheetContext.mounted ) Navigator.of( sheetContext ).pop( published );
}

Future<void> _pickFromGallery( BuildContext sheetContext, { required bool isVideo } ) async {
  final picker = ImagePicker();
  final file = isVideo
    ? await picker.pickVideo( source: ImageSource.gallery, maxDuration: const Duration( seconds: 60 ) )
    : await picker.pickImage( source: ImageSource.gallery, maxWidth: 1600, imageQuality: 90 );

  if ( file == null || !sheetContext.mounted ) return;

  final published = await Navigator.of( sheetContext ).push<bool>(
    MaterialPageRoute( builder: (_) => isVideo
      ? VideoEditorScreen( videoPath: file.path )
      : PhotoEditorScreen( imagePath: file.path ) ),
  );
  if ( sheetContext.mounted ) Navigator.of( sheetContext ).pop( published );
}
