import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum CompetitionType { featured, daily, weekly, monthly }

enum CompetitionDifficulty { beginner, intermediate, advanced, pro }

enum CompetitionStatus { upcoming, live, ended }

extension CompetitionDifficultyX on CompetitionDifficulty {
  String get label {
    switch (this) {
      case CompetitionDifficulty.beginner:
        return 'Beginner';
      case CompetitionDifficulty.intermediate:
        return 'Intermediate';
      case CompetitionDifficulty.advanced:
        return 'Advanced';
      case CompetitionDifficulty.pro:
        return 'Pro';
    }
  }

  Color get color {
    switch (this) {
      case CompetitionDifficulty.beginner:
        return AppColors.primary;
      case CompetitionDifficulty.intermediate:
        return AppColors.blue;
      case CompetitionDifficulty.advanced:
        return AppColors.orange;
      case CompetitionDifficulty.pro:
        return AppColors.error;
    }
  }
}

extension CompetitionStatusX on CompetitionStatus {
  String get label {
    switch (this) {
      case CompetitionStatus.upcoming:
        return 'Upcoming';
      case CompetitionStatus.live:
        return 'Live';
      case CompetitionStatus.ended:
        return 'Ended';
    }
  }

  Color get color {
    switch (this) {
      case CompetitionStatus.upcoming:
        return AppColors.blue;
      case CompetitionStatus.live:
        return AppColors.primary;
      case CompetitionStatus.ended:
        return AppColors.textMuted;
    }
  }
}

class CompetitionWinner {
  final String username;
  final int rank;
  final String reward;
  const CompetitionWinner({required this.username, required this.rank, required this.reward});
}

class CompetitionModel {
  final String id;
  final String title;
  final String category;
  final IconData bannerIcon;
  final List<Color> bannerGradient;
  final CompetitionDifficulty difficulty;
  final CompetitionType type;
  final int xpReward;
  final int coinReward;
  final int participants;
  final DateTime endsAt;
  final CompetitionStatus status;
  final String description;
  final List<String> rules;
  final List<String> requirements;
  final List<CompetitionWinner> previousWinners;
  final bool joined;

  const CompetitionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.bannerIcon,
    required this.bannerGradient,
    required this.difficulty,
    required this.type,
    required this.xpReward,
    required this.coinReward,
    required this.participants,
    required this.endsAt,
    required this.status,
    required this.description,
    required this.rules,
    required this.requirements,
    required this.previousWinners,
    this.joined = false,
  });

  Duration get timeLeft => endsAt.difference(DateTime.now());

  CompetitionModel copyWith({bool? joined, int? participants}) {
    return CompetitionModel(
      id: id,
      title: title,
      category: category,
      bannerIcon: bannerIcon,
      bannerGradient: bannerGradient,
      difficulty: difficulty,
      type: type,
      xpReward: xpReward,
      coinReward: coinReward,
      participants: participants ?? this.participants,
      endsAt: endsAt,
      status: status,
      description: description,
      rules: rules,
      requirements: requirements,
      previousWinners: previousWinners,
      joined: joined ?? this.joined,
    );
  }
}
