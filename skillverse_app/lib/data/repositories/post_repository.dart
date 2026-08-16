import 'dart:async';
import 'dart:io';

import '../../core/constants/feed_type.dart';
import 'package:uuid/uuid.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../services/firestore_post_service.dart';
import '../services/post_local_storage_service.dart';
import '../services/storage_upload_service.dart';

/// Business layer for posts. Screens/providers talk to this, never to
/// [FirestorePostService]/[StorageUploadService] directly, so a future
/// change to how media is hosted or how posts are queried stays a
/// one-file change.
///
/// Local storage is now scoped to just the in-progress composer draft
/// ([loadDraft]/[saveDraft]/[clearDraft]) — the posts themselves, their
/// likes, saves, and comments all live in Firestore.
class PostRepository {
  final FirestorePostService _firestore;
  final StorageUploadService _storage;
  final PostLocalStorageService _localDraft;
  final _uuid = const Uuid();

  PostRepository({
    FirestorePostService? firestore,
    StorageUploadService? storage,
    PostLocalStorageService? localDraft,
  })  : _firestore = firestore ?? FirestorePostService(),
        _storage = storage ?? StorageUploadService(),
        _localDraft = localDraft ?? PostLocalStorageService();

  String? get currentUid => _firestore.currentUid;

  // ---------------- Realtime feed ----------------

  /// Combines the posts / comments / likes / saves streams into one
  /// live `List<Post>` — the single feed [PostProvider] listens to.
  /// Every post carries this device's own likedByMe/savedByMe state
  /// and its full comment thread, kept current in realtime.
  Stream<List<Post>> watchFeed(String? uid) {
    late final StreamController<List<Post>> controller;

    List<FirestoreDoc> latestPosts = [];
    List<FirestoreDoc> latestComments = [];
    Set<String> latestLiked = {};
    Set<String> latestSaved = {};
    var gotPosts = false;

    final subs = <StreamSubscription>[];

    void emit() {
      if (!gotPosts) return; // wait for the first posts snapshot before showing anything
      final commentsByPost = <String, List<Comment>>{};
      for (final doc in latestComments) {
        final postId = doc.data['postId'] as String? ?? '';
        (commentsByPost[postId] ??= []).add(Comment.fromFirestore(doc.id, doc.data));
      }

      final posts = latestPosts
          .map((doc) => Post.fromFirestore(
                id: doc.id,
                data: doc.data,
                likedByMe: latestLiked.contains(doc.id),
                savedByMe: latestSaved.contains(doc.id),
                comments: commentsByPost[doc.id] ?? const [],
              ))
          .toList();

      controller.add(posts);
    }

    controller = StreamController<List<Post>>.broadcast(
      onListen: () {
        subs.add(_firestore.streamRecentPosts().listen((docs) {
          latestPosts = docs;
          gotPosts = true;
          emit();
        }, onError: controller.addError));

        subs.add(_firestore.streamAllComments().listen((docs) {
          latestComments = docs;
          emit();
        }, onError: controller.addError));

        if (uid != null) {
          subs.add(_firestore.streamLikedPostIds(uid).listen((ids) {
            latestLiked = ids;
            emit();
          }, onError: controller.addError));
          subs.add(_firestore.streamSavedPostIds(uid).listen((ids) {
            latestSaved = ids;
            emit();
          }, onError: controller.addError));
        }
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );

    return controller.stream;
  }

  // ---------------- Draft (still local — transient composer state) ----------------

  Future<PostDraft?> loadDraft() => _localDraft.loadDraft();
  Future<void> saveDraft(PostDraft draft) => _localDraft.saveDraft(draft);
  Future<void> clearDraft() => _localDraft.clearDraft();

  // ---------------- Publish ----------------

  /// Compresses + uploads [localMediaPath] to Storage (if present),
  /// then writes the post document. [onProgress] tracks just the
  /// upload portion (0.0–1.0); the Firestore write itself is fast
  /// enough not to need its own progress signal.
  Future<Post> publishPost({
    required String authorId,
    required String authorName,
    required String authorLevel,
    required String category,
    required String caption,
    required PostMediaType mediaType,
    String? localMediaPath,
    required void Function(double progress) onProgress,
  }) async {
    String? mediaUrl;

    if (mediaType != PostMediaType.none && localMediaPath != null) {
      var file = File(localMediaPath);
      if (mediaType == PostMediaType.image) {
        file = await _storage.compressImage(file);
      }
      final ext = mediaType == PostMediaType.image ? 'jpg' : 'mp4';
      final storagePath = 'posts/$authorId/${_uuid.v4()}.$ext';
      mediaUrl = await _storage.uploadFile(
        file: file,
        storagePath: storagePath,
        onProgress: onProgress,
      );
    } else {
      onProgress(1);
    }

    final id = await _firestore.createPost({
      'authorId': authorId,
      'authorName': authorName,
      'authorLevel': authorLevel,
      'category': category,
      'caption': caption.trim(),
      'mediaType': mediaType.name,
      'mediaUrl': mediaUrl,
      'likeCount': 0,
    });

    return Post(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorLevel: authorLevel,
      category: category,
      caption: caption.trim(),
      mediaType: mediaType,
      mediaPath: mediaUrl,
      createdAt: DateTime.now(),
    );
  }

  // ---------------- Likes / saves ----------------

  Future<void> setLiked({required String postId, required String uid, required bool liked}) =>
      _firestore.setLiked(postId: postId, uid: uid, liked: liked);

  Future<void> setSaved({required String postId, required String uid, required bool saved}) =>
      _firestore.setSaved(postId: postId, uid: uid, saved: saved);

  // ---------------- Comments ----------------

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String authorLevel,
    required String text,
    String? parentId,
  }) {
    return _firestore.addComment({
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorLevel': authorLevel,
      'text': text.trim(),
      'parentId': parentId,
    });
  }

  Future<void> editComment({required String commentId, required String newText}) =>
      _firestore.editComment(commentId, newText.trim());

  Future<void> deleteComment(String commentId) => _firestore.deleteComment(commentId);

  // ---------------- Client-side sort/filter/paginate (unchanged) ----------------

  /// Filters + sorts [source] for [type]/[category], then returns just
  /// the requested page. Runs entirely in memory over whatever the
  /// live feed currently holds — same behavior as before Firestore,
  /// just now over realtime data instead of a static local list.
  List<Post> paginate({
    required List<Post> source,
    required FeedType type,
    String? category,
    required int page,
    int pageSize = 6,
  }) {
    var items = category == null
        ? List<Post>.from(source)
        : source.where((p) => p.category == category).toList();

    switch (type) {
      case FeedType.latest:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case FeedType.trending:
        items.sort((a, b) {
          final scoreA = a.likes + a.commentCount * 2;
          final scoreB = b.likes + b.commentCount * 2;
          final cmp = scoreB.compareTo(scoreA);
          return cmp != 0 ? cmp : b.createdAt.compareTo(a.createdAt);
        });
        break;
      case FeedType.recommended:
        items.sort((a, b) {
          double score(Post p) {
            final hoursOld = DateTime.now().difference(p.createdAt).inMinutes / 60.0;
            final recencyBonus = (48 - hoursOld).clamp(0, 48) * 3;
            return p.likes * 0.6 + p.commentCount * 1.5 + recencyBonus;
          }

          return score(b).compareTo(score(a));
        });
        break;
    }

    final start = page * pageSize;
    if (start >= items.length) return [];
    final end = (start + pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  int countFor({required List<Post> source, String? category}) {
    if (category == null) return source.length;
    return source.where((p) => p.category == category).length;
  }
}
