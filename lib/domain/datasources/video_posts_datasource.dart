import 'package:toktok/domain/entities/video_post.dart';


abstract class VideoPostsDatasource {

  Future<List<VideoPost>> getTrendingVideosByPage( int page );

}
