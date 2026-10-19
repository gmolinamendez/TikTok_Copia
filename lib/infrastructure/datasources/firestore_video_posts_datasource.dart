import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toktok/domain/datasources/video_posts_datasource.dart';
import 'package:toktok/domain/entities/face_frame.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/infrastructure/models/firestore_video_model.dart';


// Colección `videos` en Firestore. Cada like se guarda en `videos/{id}/likes/{userId}`
// y el contador `likes` del video se actualiza en el mismo batch.
class FirestoreVideoPostsDatasource extends VideoPostsDatasource {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _videos => _firestore.collection('videos');

  @override
  Future<List<VideoPost>> getTrendingVideosByPage( int page, { String? userId } ) async {

    final snapshot = await _videos.orderBy('order').get();

    final models = snapshot.docs
      .map( FirestoreVideoModel.fromFirestore )
      .where( (video) => video.videoUrl.isNotEmpty );

    return Future.wait( models.map( (video) async {
      final isLiked = userId != null
        && ( await _videos.doc( video.id ).collection('likes').doc( userId ).get() ).exists;
      return video.toVideoPostEntity( isLiked: isLiked );
    }));
  }

  @override
  Future<void> createPost({
    required String title,
    required String mediaUrl,
    required MediaType mediaType,
    required String userId,
    required String? userEmail,
    String filterId = 'none',
    List<FaceFrame> faceTrack = const [],
  }) {
    final now = DateTime.now();
    return _videos.add({
      'title': title,
      'videoUrl': mediaUrl,
      'mediaType': mediaType.name,
      'likes': 0,
      'views': 0,
      // Los videos de ejemplo usan order 1..5; los nuevos usan un número negativo
      // para que aparezcan primero (el más reciente arriba).
      'order': -now.millisecondsSinceEpoch,
      'createdAt': Timestamp.fromDate( now ),
      'userId': userId,
      'userEmail': userEmail,
      'filterId': filterId,
      'faceTrack': faceTrack.map( (frame) => frame.toJson() ).toList(),
    });
  }

  @override
  Future<void> setLike({ required String postId, required String userId, required bool liked }) {
    final videoRef = _videos.doc( postId );
    final likeRef = videoRef.collection('likes').doc( userId );

    final batch = _firestore.batch();
    if ( liked ) {
      batch.set( likeRef, { 'createdAt': FieldValue.serverTimestamp() } );
    } else {
      batch.delete( likeRef );
    }
    batch.update( videoRef, { 'likes': FieldValue.increment( liked ? 1 : -1 ) } );
    return batch.commit();
  }

}
