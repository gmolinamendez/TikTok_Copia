import 'package:toktok/domain/entities/face_frame.dart';


enum MediaType { video, image }

class VideoPost {

  final String id;
  final String caption;
  final String videoUrl;
  final MediaType mediaType;
  final int likes;
  final int views;
  final bool isLiked;
  final String filterId;
  final List<FaceFrame> faceTrack;
  final String? userEmail;

  VideoPost({
    this.id = '',
    required this.caption,
    required this.videoUrl,
    this.mediaType = MediaType.video,
    this.likes = 0,
    this.views = 0,
    this.isLiked = false,
    this.filterId = 'none',
    this.faceTrack = const [],
    this.userEmail,
  });

  bool get isImage => mediaType == MediaType.image;

  VideoPost copyWith({ int? likes, bool? isLiked }) => VideoPost(
    id: id,
    caption: caption,
    videoUrl: videoUrl,
    mediaType: mediaType,
    likes: likes ?? this.likes,
    views: views,
    isLiked: isLiked ?? this.isLiked,
    filterId: filterId,
    faceTrack: faceTrack,
    userEmail: userEmail,
  );

}
