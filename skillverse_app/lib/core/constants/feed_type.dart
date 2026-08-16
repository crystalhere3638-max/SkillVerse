import 'package:flutter/material.dart';

enum FeedType { trending, latest, recommended }

extension FeedTypeX on FeedType {
  String get label {
    switch (this) {
      case FeedType.trending:
        return 'Trending';
      case FeedType.latest:
        return 'Latest';
      case FeedType.recommended:
        return 'For You';
    }
  }

  IconData get icon {
    switch (this) {
      case FeedType.trending:
        return Icons.local_fire_department_rounded;
      case FeedType.latest:
        return Icons.access_time_rounded;
      case FeedType.recommended:
        return Icons.auto_awesome_rounded;
    }
  }
}
