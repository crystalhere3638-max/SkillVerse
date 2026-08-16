import 'package:cloud_firestore/cloud_firestore.dart';

import 'comment_model.dart';

enum PostMediaType { none, image, video }

/// A single feed post. [mediaPath] holds a Firebase Storage download
/// URL for published posts (see [PostRepository.publishPost]) — it's
/// only a bare local file path transiently, while a draft is still
/// being composed and not yet uploaded.
class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String authorLevel;
  final String category;
  final String caption;
  final PostMediaType mediaType;
  final String? mediaPath;
  final DateTime createdAt;
  final int likes;
  final bool likedByMe;
  final bool savedByMe;

  /// Baseline comment count for mock/seed posts (so the feed doesn't
  /// need 28 fabricated comment threads just to show a number).
  final int mockCommentCount;

  /// Real comments/replies added this session. Total shown to the
  /// user is [mockCommentCount] + [comments.length].
  final List<Comment> comments;

  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorLevel,
    required this.category,
    required this.caption,
    required this.mediaType,
    this.mediaPath,
    required this.createdAt,
    this.likes = 0,
    this.likedByMe = false,
    this.savedByMe = false,
    this.mockCommentCount = 0,
    this.comments = const [],
  });

  int get commentCount => mockCommentCount + comments.length;

  /// Top-level comments (not replies), newest first.
  List<Comment> get topLevelComments =>
      comments.where((c) => !c.isReply).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<Comment> repliesTo(String commentId) =>
      comments.where((c) => c.parentId == commentId).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Post copyWith({
    int? likes,
    bool? likedByMe,
    bool? savedByMe,
    List<Comment>? comments,
  }) {
    return Post(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorLevel: authorLevel,
      category: category,
      caption: caption,
      mediaType: mediaType,
      mediaPath: mediaPath,
      createdAt: createdAt,
      likes: likes ?? this.likes,
      likedByMe: likedByMe ?? this.likedByMe,
      savedByMe: savedByMe ?? this.savedByMe,
      mockCommentCount: mockCommentCount,
      comments: comments ?? this.comments,
    );
  }

  /// Builds a [Post] from a `posts/{id}` Firestore document. Unlike
  /// [fromJson] (used for the local draft cache only), this does NOT
  /// read likes/saves/comments from the document itself — those live
  /// in their own top-level collections and are merged in by
  /// [PostRepository] after querying them separately, since per-user
  /// like/save state can't be stored on a shared document.
  factory Post.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
    required bool likedByMe,
    required bool savedByMe,
    required List<Comment> comments,
  }) {
    final createdAtRaw = data['createdAt'];
    return Post(
      id: id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Unknown',
      authorLevel: data['authorLevel'] as String? ?? 'Lv.1',
      category: data['category'] as String? ?? 'General',
      caption: data['caption'] as String? ?? '',
      mediaType: PostMediaType.values.firstWhere(
        (t) => t.name == data['mediaType'],
        orElse: () => PostMediaType.none,
      ),
      mediaPath: data['mediaUrl'] as String?,
      // Firestore Timestamps arrive as a Timestamp object with
      // .toDate(); fall back to "now" only if a write is still
      // pending server assignment (serverTimestamp() reads null
      // locally until the server round-trip completes).
      createdAt: createdAtRaw is Timestamp ? createdAtRaw.toDate() : DateTime.now(),
      likes: (data['likeCount'] as num?)?.toInt() ?? 0,
      likedByMe: likedByMe,
      savedByMe: savedByMe,
      mockCommentCount: 0,
      comments: comments,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorLevel': authorLevel,
        'category': category,
        'caption': caption,
        'mediaType': mediaType.name,
        'mediaPath': mediaPath,
        'createdAt': createdAt.toIso8601String(),
        'likes': likes,
        'likedByMe': likedByMe,
        'savedByMe': savedByMe,
        'mockCommentCount': mockCommentCount,
        'comments': comments.map((c) => c.toJson()).toList(),
      };

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String,
        authorId: json['authorId'] as String? ?? '',
        authorName: json['authorName'] as String,
        authorLevel: json['authorLevel'] as String,
        category: json['category'] as String,
        caption: json['caption'] as String,
        mediaType: PostMediaType.values.firstWhere(
          (t) => t.name == json['mediaType'],
          orElse: () => PostMediaType.none,
        ),
        mediaPath: json['mediaPath'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        likedByMe: (json['likedByMe'] as bool?) ?? false,
        savedByMe: (json['savedByMe'] as bool?) ?? false,
        // Back-compat: older persisted posts stored a plain int under
        // 'comments' — treat that as the mock seed count so existing
        // local data doesn't break.
        mockCommentCount: (json['mockCommentCount'] as num?)?.toInt() ??
            (json['comments'] is num ? (json['comments'] as num).toInt() : 0),
        comments: json['comments'] is List
            ? (json['comments'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => Comment.fromJson(e))
                .toList()
            : const [],
      );
}

/// An in-progress, unpublished post — kept separate from [Post] since
/// it has no id/timestamp/engagement fields yet.
class PostDraft {
  final String caption;
  final String? category;
  final PostMediaType mediaType;
  final String? mediaPath;

  const PostDraft({
    this.caption = '',
    this.category,
    this.mediaType = PostMediaType.none,
    this.mediaPath,
  });

  bool get isEmpty => caption.trim().isEmpty && mediaType == PostMediaType.none;

  Map<String, dynamic> toJson() => {
        'caption': caption,
        'category': category,
        'mediaType': mediaType.name,
        'mediaPath': mediaPath,
      };

  factory PostDraft.fromJson(Map<String, dynamic> json) => PostDraft(
        caption: json['caption'] as String? ?? '',
        category: json['category'] as String?,
        mediaType: PostMediaType.values.firstWhere(
          (t) => t.name == json['mediaType'],
          orElse: () => PostMediaType.none,
        ),
        mediaPath: json['mediaPath'] as String?,
      );
}
