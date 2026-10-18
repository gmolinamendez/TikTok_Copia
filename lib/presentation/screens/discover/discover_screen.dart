import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
import 'package:toktok/presentation/widgets/shared/video_scrollable_view.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

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
      body: message != null
        ? Center( child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text( message, textAlign: TextAlign.center ),
          ))
        : VideoScrollableView(videos: discoverProvider.videos )
    );
  }
}
