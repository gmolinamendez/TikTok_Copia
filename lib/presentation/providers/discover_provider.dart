import 'package:flutter/material.dart';
import 'package:toktok/domain/datasources/video_posts_datasource.dart';
import 'package:toktok/domain/entities/video_post.dart';



class DiscoverProvider extends ChangeNotifier {

  final VideoPostsDatasource videosDatasource;
  final String userId;

  bool initialLoading = true;
  String? errorMessage;
  List<VideoPost> videos = [];

  DiscoverProvider({ required this.videosDatasource, required this.userId });


  Future<void> loadNextPage() async {

    try {
      final newVideos = await videosDatasource.getTrendingVideosByPage( 1, userId: userId );
      videos = newVideos;
      errorMessage = null;
    } catch (e) {
      errorMessage = 'No se pudieron cargar los videos: $e';
    }

    initialLoading = false;
    notifyListeners();
  }

  Future<void> toggleLike( VideoPost post ) async {
    final index = videos.indexWhere( (video) => video.id == post.id );
    if ( index == -1 ) return;

    final liked = !post.isLiked;

    // Se actualiza la pantalla al instante y, si Firebase falla, se regresa como estaba
    videos[index] = post.copyWith( isLiked: liked, likes: post.likes + ( liked ? 1 : -1 ) );
    notifyListeners();

    try {
      await videosDatasource.setLike( postId: post.id, userId: userId, liked: liked );
    } catch (e) {
      videos[index] = post;
      notifyListeners();
    }
  }


}
