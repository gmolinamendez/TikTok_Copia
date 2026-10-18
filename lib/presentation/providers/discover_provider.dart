import 'package:flutter/material.dart';
import 'package:toktok/domain/datasources/video_posts_datasource.dart';
import 'package:toktok/domain/entities/video_post.dart';



class DiscoverProvider extends ChangeNotifier {

  final VideoPostsDatasource videosDatasource;

  bool initialLoading = true;
  String? errorMessage;
  List<VideoPost> videos = [];

  DiscoverProvider({ required this.videosDatasource });


  Future<void> loadNextPage() async {

    try {
      final newVideos = await videosDatasource.getTrendingVideosByPage(1);
      videos.addAll( newVideos );
    } catch (e) {
      errorMessage = 'No se pudieron cargar los videos: $e';
    }

    initialLoading = false;
    notifyListeners();
  }


}
