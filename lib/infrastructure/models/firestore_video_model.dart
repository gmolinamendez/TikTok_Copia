import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toktok/domain/entities/face_frame.dart';
import 'package:toktok/domain/entities/video_post.dart';


class FirestoreVideoModel {

  final String id;
  final String title;
  final String videoUrl;
  final String mediaType;
  final int likes;
  final int views;
  final String filterId;
  final List<FaceFrame> faceTrack;
  final String? userEmail;

  FirestoreVideoModel({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.mediaType = 'video',
    this.likes = 0,
    this.views = 0,
    this.filterId = 'none',
    this.faceTrack = const [],
    this.userEmail,
  });

  factory FirestoreVideoModel.fromFirestore( DocumentSnapshot<Map<String, dynamic>> doc ) {
    final json = doc.data() ?? {};
    return FirestoreVideoModel(
      id: doc.id,
      title: json['title'] ?? 'Sin título',
      videoUrl: json['videoUrl'] ?? '',
      mediaType: json['mediaType'] ?? 'video',
      likes: json['likes'] ?? 0,
      views: json['views'] ?? 0,
      filterId: json['filterId'] ?? 'none',
      faceTrack: ( json['faceTrack'] as List? ?? [] )
        .map( (frame) => FaceFrame.fromJson( Map<String, dynamic>.from(frame) ) )
        .toList(),
      userEmail: json['userEmail'],
    );
  }

  VideoPost toVideoPostEntity({ bool isLiked = false }) => VideoPost(
    id: id,
    caption: title,
    videoUrl: videoUrl,
    mediaType: mediaType == 'image' ? MediaType.image : MediaType.video,
    likes: likes,
    views: views,
    isLiked: isLiked,
    filterId: filterId,
    faceTrack: faceTrack,
    userEmail: userEmail,
  );

}
