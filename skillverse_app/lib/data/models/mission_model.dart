import 'package:flutter/material.dart';

class MissionModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int progress;
  final int target;
  final int xpReward;
  final int coinReward;
  final bool claimed;

  const MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.target,
    required this.xpReward,
    required this.coinReward,
    this.claimed = false,
  });

  bool get isCompleted => progress >= target;
  double get progressFraction => target == 0 ? 0 : (progress / target).clamp(0, 1).toDouble();

  MissionModel copyWith({int? progress, bool? claimed}) {
    return MissionModel(
      id: id,
      title: title,
      description: description,
      icon: icon,
      progress: progress ?? this.progress,
      target: target,
      xpReward: xpReward,
      coinReward: coinReward,
      claimed: claimed ?? this.claimed,
    );
  }
}
