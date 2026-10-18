import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toktok/domain/entities/video_post.dart';


class FirestoreVideoModel {

  final String title;
  final String videoUrl;
  final int likes;
  final int views;

  FirestoreVideoModel({
    required this.title,
    required this.videoUrl,
    this.likes = 0,
    this.views = 0
  });

  factory FirestoreVideoModel.fromFirestore( DocumentSnapshot<Map<String, dynamic>> doc ) {
    final json = doc.data() ?? {};
    return FirestoreVideoModel(
      title: json['title'] ?? 'Sin título',
      videoUrl: json['videoUrl'] ?? '',
      likes: json['likes'] ?? 0,
      views: json['views'] ?? 0,
    );
  }

  VideoPost toVideoPostEntity() => VideoPost(
    caption: title,
    videoUrl: videoUrl,
    likes: likes,
    views: views
  );

}
