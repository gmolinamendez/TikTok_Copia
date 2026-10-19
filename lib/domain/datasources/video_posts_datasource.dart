import 'package:toktok/domain/entities/face_frame.dart';
import 'package:toktok/domain/entities/video_post.dart';


abstract class VideoPostsDatasource {

  Future<List<VideoPost>> getTrendingVideosByPage( int page, { String? userId } );

  Future<void> createPost({
    required String title,
    required String mediaUrl,
    required MediaType mediaType,
    required String userId,
    required String? userEmail,
    String filterId = 'none',
    List<FaceFrame> faceTrack = const [],
  });

  Future<void> setLike({ required String postId, required String userId, required bool liked });

}
