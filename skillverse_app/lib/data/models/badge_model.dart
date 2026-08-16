import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum BadgeTier { bronze, silver, gold, platinum }

extension BadgeTierX on BadgeTier {
  String get label {
    switch (this) {
      case BadgeTier.bronze:
        return 'Bronze';
      case BadgeTier.silver:
        return 'Silver';
      case BadgeTier.gold:
        return 'Gold';
      case BadgeTier.platinum:
        return 'Platinum';
    }
  }

  Color get color {
    switch (this) {
      case BadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case BadgeTier.silver:
        return const Color(0xFFC0C0C0);
      case BadgeTier.gold:
        return AppColors.gold;
      case BadgeTier.platinum:
        return const Color(0xFF9EE7E0);
    }
  }
}

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final BadgeTier tier;
  final bool unlocked;
  final DateTime? unlockedAt;
  final String requirement;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.tier,
    required this.requirement,
    this.unlocked = false,
    this.unlockedAt,
  });
}
