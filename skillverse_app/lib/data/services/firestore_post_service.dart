import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A raw (id, data) pair straight off a Firestore snapshot — kept
/// generic here since turning it into a [Post]/[Comment] needs data
/// merged from more than one collection (see [PostRepository]).
class FirestoreDoc {
  final String id;
  final Map<String, dynamic> data;
  const FirestoreDoc(this.id, this.data);
}

/// Talks to the `posts`, `likes`, `saves`, and `comments` top-level
/// collections. No SharedPreferences/local persistence lives here —
/// that's [PostLocalStorageService]'s job now, scoped to just the
/// in-progress composer draft.
class FirestorePostService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  FirestorePostService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _posts => _db.collection('posts');
  CollectionReference<Map<String, dynamic>> get _likes => _db.collection('likes');
  CollectionReference<Map<String, dynamic>> get _saves => _db.collection('saves');
  CollectionReference<Map<String, dynamic>> get _comments => _db.collection('comments');

  // ---------------- Posts ----------------

  /// Live feed of the most recent posts. Bounded by [limit] rather
  /// than true cursor pagination for now — [PostProvider] still does
  /// its existing client-side sort/filter/paginate over this working
  /// set, which keeps every screen's pagination UX identical while
  /// still being fully realtime. Raising [limit] or moving to
  /// `startAfterDocument` cursors later is a repository-only change.
  Stream<List<FirestoreDoc>> streamRecentPosts({int limit = 200}) {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FirestoreDoc(d.id, d.data())).toList());
  }

  Future<String> createPost(Map<String, dynamic> data) async {
    final doc = await _posts.add({...data, 'createdAt': FieldValue.serverTimestamp()});
    return doc.id;
  }
  Future<void> deletePost(String postId) async {
    await _posts.doc(postId).delete();

    final likeDocs = await _likes.where('postId', isEqualTo: postId).get();
    for (final doc in likeDocs.docs) {
      await doc.reference.delete();
    }

    final saveDocs = await _saves.where('postId', isEqualTo: postId).get();
    for (final doc in saveDocs.docs) {
      await doc.reference.delete();
    }

    final commentDocs = await _comments.where('postId', isEqualTo: postId).get();
    for (final doc in commentDocs.docs) {
      await doc.reference.delete();
    }
  }

  // ---------------- Likes ----------------

  String _likeDocId(String postId, String uid) => '${postId}_$uid';

  Stream<Set<String>> streamLikedPostIds(String uid) {
    return _likes.where('userId', isEqualTo: uid).snapshots().map(
          (snap) => snap.docs.map((d) => d.data()['postId'] as String).toSet(),
        );
  }

  Future<void> setLiked({required String postId, required String uid, required bool liked}) async {
    final likeRef = _likes.doc(_likeDocId(postId, uid));
    final postRef = _posts.doc(postId);

    await _db.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      final alreadyLiked = likeSnap.exists;
      if (liked == alreadyLiked) return; // already in the desired state

      if (liked) {
        tx.set(likeRef, {
          'postId': postId,
          'userId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(postRef, {'likeCount': FieldValue.increment(1)});
      } else {
        tx.delete(likeRef);
        tx.update(postRef, {'likeCount': FieldValue.increment(-1)});
      }
    });
  }

  // ---------------- Saves ----------------

  String _saveDocId(String postId, String uid) => '${postId}_$uid';

  Stream<Set<String>> streamSavedPostIds(String uid) {
    return _saves.where('userId', isEqualTo: uid).snapshots().map(
          (snap) => snap.docs.map((d) => d.data()['postId'] as String).toSet(),
        );
  }

  Future<void> setSaved({required String postId, required String uid, required bool saved}) async {
    final ref = _saves.doc(_saveDocId(postId, uid));
    if (saved) {
      await ref.set({'postId': postId, 'userId': uid, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
  }

  // ---------------- Comments ----------------

  /// One listener for the whole collection, merged client-side by
  /// [PostRepository]. Simple and realtime; if comment volume grows
  /// large enough to matter, swap this for per-post listeners opened
  /// only while that post's comment sheet is visible — no public API
  /// change needed for that later optimization.
  Stream<List<FirestoreDoc>> streamAllComments() {
    return _comments
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map((d) => FirestoreDoc(d.id, d.data())).toList());
  }

  Future<void> addComment(Map<String, dynamic> data) async {
    await _comments.add({...data, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> editComment(String commentId, String newText) async {
    await _comments.doc(commentId).update({
      'text': newText,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes a comment and, if it was a top-level comment, every
  /// reply pointing at it — matches the existing local-mock behavior.
  Future<void> deleteComment(String commentId) async {
    final batch = _db.batch();
    batch.delete(_comments.doc(commentId));
    final replies = await _comments.where('parentId', isEqualTo: commentId).get();
    for (final reply in replies.docs) {
      batch.delete(reply.reference);
    }
    await batch.commit();
  }
}
