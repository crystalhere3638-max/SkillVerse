import 'comment_model.dart';

/// Where the bytes for a video actually come from. User-published
/// videos are uploaded to Firebase Storage (see
/// [VideoRepository.publishVideo]) and always end up as [network]
/// with a real download URL. Seed/mock videos also use small public
/// sample clips over the network so the Videos tab has real,
/// playable content to scroll through for testing. [local] is kept
/// only so [VideoPost.fromJson] can gracefully read any video cached
/// locally before Storage upload was wired in — nothing writes it now.
enum VideoSource { local, network }

/// A single short-form video in the Videos feed.
class VideoPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorLevel;
  final String category;
  final String caption;
  final String videoUrl;
  final VideoSource source;
  final DateTime createdAt;

  final int likes;
  final bool likedByMe;
  final bool savedByMe;
  final int views;
  final int shares;

  /// Baseline comment count for mock/seed videos, mirroring
  /// [Post.mockCommentCount] — same reasoning: avoids fabricating a
  /// full comment thread just to show a realistic number.
  final int mockCommentCount;
  final List<Comment> comments;

  /// Competition tie-in: when non-null, the feed shows a small trophy
  /// badge on the card (e.g. "Weekly Challenge Winner", "Competition
  /// Entry"). Purely presentational for now — not wired to
  /// [CompetitionProvider] yet since that would mean generating real
  /// competition results, which is out of scope here.
  final String? competitionBadge;

  const VideoPost({
    required this.id,
    this.authorId = '',
    required this.authorName,
    required this.authorLevel,
    required this.category,
    required this.caption,
    required this.videoUrl,
    required this.source,
    required this.createdAt,
    this.likes = 0,
    this.likedByMe = false,
    this.savedByMe = false,
    this.views = 0,
    this.shares = 0,
    this.mockCommentCount = 0,
    this.comments = const [],
    this.competitionBadge,
  });

  bool get hasCompetitionBadge => competitionBadge != null;
  int get commentCount => mockCommentCount + comments.length;

  List<Comment> get topLevelComments =>
      comments.where((c) => !c.isReply).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<Comment> repliesTo(String commentId) =>
      comments.where((c) => c.parentId == commentId).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  VideoPost copyWith({
    int? likes,
    bool? likedByMe,
    bool? savedByMe,
    int? views,
    int? shares,
    List<Comment>? comments,
  }) {
    return VideoPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorLevel: authorLevel,
      category: category,
      caption: caption,
      videoUrl: videoUrl,
      source: source,
      createdAt: createdAt,
      likes: likes ?? this.likes,
      likedByMe: likedByMe ?? this.likedByMe,
      savedByMe: savedByMe ?? this.savedByMe,
      views: views ?? this.views,
      shares: shares ?? this.shares,
      mockCommentCount: mockCommentCount,
      comments: comments ?? this.comments,
      competitionBadge: competitionBadge,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorLevel': authorLevel,
        'category': category,
        'caption': caption,
        'videoUrl': videoUrl,
        'source': source.name,
        'createdAt': createdAt.toIso8601String(),
        'likes': likes,
        'likedByMe': likedByMe,
        'savedByMe': savedByMe,
        'views': views,
        'shares': shares,
        'mockCommentCount': mockCommentCount,
        'comments': comments.map((c) => c.toJson()).toList(),
        'competitionBadge': competitionBadge,
      };

  factory VideoPost.fromJson(Map<String, dynamic> json) => VideoPost(
        id: json['id'] as String,
        authorId: json['authorId'] as String? ?? '',
        authorName: json['authorName'] as String,
        authorLevel: json['authorLevel'] as String,
        category: json['category'] as String,
        caption: json['caption'] as String,
        videoUrl: json['videoUrl'] as String,
        source: VideoSource.values.firstWhere(
          (s) => s.name == json['source'],
          orElse: () => VideoSource.network,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        likedByMe: (json['likedByMe'] as bool?) ?? false,
        savedByMe: (json['savedByMe'] as bool?) ?? false,
        views: (json['views'] as num?)?.toInt() ?? 0,
        shares: (json['shares'] as num?)?.toInt() ?? 0,
        mockCommentCount: (json['mockCommentCount'] as num?)?.toInt() ?? 0,
        comments: json['comments'] is List
            ? (json['comments'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => Comment.fromJson(e))
                .toList()
            : const [],
        competitionBadge: json['competitionBadge'] as String?,
      );
}
