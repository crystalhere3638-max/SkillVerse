import 'package:cloud_firestore/cloud_firestore.dart';

/// Writes a record of each published video to the `videos` Firestore
/// collection so its Storage download URL isn't local-only. This is
/// deliberately write-only for now — [VideoProvider]'s feed still
/// reads from local storage (that's a separate, larger migration, not
/// part of the Storage-integration task this was built for). Nothing
/// currently reads these documents back; they exist so the URL has a
/// durable home from day one and the eventual Videos migration has
/// real data to point at instead of starting from zero.
class FirestoreVideoService {
  final FirebaseFirestore _db;
  FirestoreVideoService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> recordPublishedVideo(Map<String, dynamic> data) async {
    await _db.collection('videos').add({...data, 'createdAt': FieldValue.serverTimestamp()});
  }
}
