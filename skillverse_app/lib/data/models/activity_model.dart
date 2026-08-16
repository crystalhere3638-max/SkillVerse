import 'package:flutter/material.dart';

enum ActivityType { liked, commented, replied, saved, published }

extension ActivityTypeX on ActivityType {
  IconData get icon {
    switch (this) {
      case ActivityType.liked:
        return Icons.favorite_rounded;
      case ActivityType.commented:
        return Icons.chat_bubble_rounded;
      case ActivityType.replied:
        return Icons.reply_rounded;
      case ActivityType.saved:
        return Icons.bookmark_rounded;
      case ActivityType.published:
        return Icons.upload_rounded;
    }
  }

  String verb() {
    switch (this) {
      case ActivityType.liked:
        return 'You liked a post';
      case ActivityType.commented:
        return 'You commented on a post';
      case ActivityType.replied:
        return 'You replied to a comment';
      case ActivityType.saved:
        return 'You saved a post';
      case ActivityType.published:
        return 'You published a post';
    }
  }
}

/// One row in the user's activity feed. Kept intentionally small —
/// enough to render "You liked a post in Programming · 2h ago"
/// without needing to re-fetch the underlying post.
class ActivityEntry {
  final String id;
  final ActivityType type;
  final String postId;
  final String postCategory;
  final DateTime timestamp;

  const ActivityEntry({
    required this.id,
    required this.type,
    required this.postId,
    required this.postCategory,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'postId': postId,
        'postCategory': postCategory,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ActivityEntry.fromJson(Map<String, dynamic> json) => ActivityEntry(
        id: json['id'] as String,
        type: ActivityType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => ActivityType.liked,
        ),
        postId: json['postId'] as String,
        postCategory: (json['postCategory'] as String?) ?? '',
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

