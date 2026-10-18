import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toktok/domain/datasources/video_posts_datasource.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/infrastructure/models/firestore_video_model.dart';


// Lee los videos (título, URL, likes, views) de la colección `videos` en Firestore.
class FirestoreVideoPostsDatasource extends VideoPostsDatasource {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<VideoPost>> getTrendingVideosByPage( int page ) async {

    final snapshot = await _firestore
      .collection('videos')
      .orderBy('order')
      .get();

    return snapshot.docs
      .map( FirestoreVideoModel.fromFirestore )
      .where( (video) => video.videoUrl.isNotEmpty )
      .map( (video) => video.toVideoPostEntity() )
      .toList();
  }

}
