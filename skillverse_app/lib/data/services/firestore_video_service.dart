import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/video_post_model.dart';

class FirestoreVideoService {
  final FirebaseFirestore _db;
  FirestoreVideoService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> recordPublishedVideo(Map<String, dynamic> data) async {
    final id = data['id'] as String;
    await _db.collection('videos').doc(id).set({...data, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<List<VideoPost>> fetchVideos() async {
    final snap = await _db.collection('videos').orderBy('createdAt', descending: true).limit(50).get();
    final result = <VideoPost>[];
    for (final doc in snap.docs) {
      try {
        final d = doc.data();
        final ts = d['createdAt'];
        result.add(VideoPost(
          id: (d['id'] as String?) ?? doc.id,
          authorId: (d['authorId'] as String?) ?? '',
          authorName: (d['authorName'] as String?) ?? 'Learner',
          authorLevel: (d['authorLevel'] as String?) ?? 'Lv.1',
          category: (d['category'] as String?) ?? 'General',
          caption: (d['caption'] as String?) ?? '',
          videoUrl: d['videoUrl'] as String,
          source: VideoSource.network,
          createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
        ));
      } catch (_) {}
    }
    return result;
  }

  Future<void> deleteVideo(String id) async {
    await _db.collection('videos').doc(id).delete();
  }
}
