import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
import 'package:toktok/presentation/screens/create/create_post_sheet.dart';
import 'package:toktok/presentation/widgets/shared/video_scrollable_view.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  Future<void> _createPost( BuildContext context ) async {
    final published = await showCreatePostSheet( context );
    if ( published == true && context.mounted ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar( content: Text('¡Publicado!') ) );
      context.read<DiscoverProvider>().loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {

    final discoverProvider = context.watch<DiscoverProvider>();

    if ( discoverProvider.initialLoading ) {
      return const Scaffold(
        body: Center( child: CircularProgressIndicator( strokeWidth: 2 ) )
      );
    }

    final message = discoverProvider.errorMessage
      ?? ( discoverProvider.videos.isEmpty ? 'Todavía no hay videos en Firebase' : null );

    return Scaffold(
      body: Stack(
        children: [

          message != null
            ? Center( child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text( message, textAlign: TextAlign.center ),
              ))
            : VideoScrollableView(videos: discoverProvider.videos ),

          // Cerrar sesión
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: () => context.read<AuthProvider>().logout(),
                icon: const Icon( Icons.logout ),
              ),
            ),
          ),

        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nueva publicación',
        onPressed: () => _createPost( context ),
        child: const Icon( Icons.add ),
      ),
    );
  }
}
