import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

/// Thin wrapper around the `users` collection. No validation or
/// business rules here — that belongs in [UserRepository].
class FirestoreUserService {
  final FirebaseFirestore _db;

  FirestoreUserService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  Future<bool> exists(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists;
  }

  Future<void> createUser(AppUser user) {
    return _users.doc(user.uid).set(user.toCreateMap());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromDoc(doc);
    });
  }

  Future<void> updateLastLogin(String uid) {
    return _users.doc(uid).update({'lastLogin': FieldValue.serverTimestamp()});
  }

  Future<void> updateOnboarding({
    required String uid,
    required String mainCategory,
    required String goal,
  }) {
    return _users.doc(uid).update({
      'mainCategory': mainCategory,
      'goal': goal,
    });
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> fields) {
    return _users.doc(uid).update(fields);
  }

  Future<void> updatePhotoUrl(String uid, String photoUrl) {
    return _users.doc(uid).update({'photoUrl': photoUrl});
  }
}
