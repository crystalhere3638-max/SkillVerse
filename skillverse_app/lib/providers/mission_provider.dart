import 'package:flutter/material.dart';
import '../data/models/mission_model.dart';

/// Drives the Daily Missions screen. Generates exactly 3 missions per
/// day and tracks progress/claim state locally (mock data — a real
/// backend can replace [_seedMissions] later).
class MissionProvider extends ChangeNotifier {
  List<MissionModel> _missions = [];
  List<MissionModel> get missions => _missions;

  int _totalXpClaimedToday = 0;
  int _totalCoinsClaimedToday = 0;
  int get totalXpClaimedToday => _totalXpClaimedToday;
  int get totalCoinsClaimedToday => _totalCoinsClaimedToday;

  int get completedCount => _missions.where((m) => m.isCompleted).length;
  bool get allClaimed => _missions.every((m) => m.claimed);

  MissionProvider() {
    _missions = _seedMissions();
  }

  /// Returns the reward for the UI to show in a celebration animation.
  (int xp, int coins)? claim(String id) {
    final index = _missions.indexWhere((m) => m.id == id);
    if (index == -1) return null;
    final mission = _missions[index];
    if (!mission.isCompleted || mission.claimed) return null;

    _missions[index] = mission.copyWith(claimed: true);
    _totalXpClaimedToday += mission.xpReward;
    _totalCoinsClaimedToday += mission.coinReward;
    notifyListeners();
    return (mission.xpReward, mission.coinReward);
  }

  List<MissionModel> _seedMissions() {
    return const [
      MissionModel(
        id: 'mission_01',
        title: 'Post a Skill Update',
        description: 'Share one post showing progress in your skill category',
        icon: Icons.upload_rounded,
        progress: 1,
        target: 1,
        xpReward: 40,
        coinReward: 20,
      ),
      MissionModel(
        id: 'mission_02',
        title: 'Engage With the Community',
        description: 'Like or comment on 5 posts from other learners',
        icon: Icons.favorite_rounded,
        progress: 3,
        target: 5,
        xpReward: 30,
        coinReward: 15,
      ),
      MissionModel(
        id: 'mission_03',
        title: 'Join a Competition',
        description: 'Enter any daily or weekly competition',
        icon: Icons.emoji_events_rounded,
        progress: 0,
        target: 1,
        xpReward: 50,
        coinReward: 25,
      ),
    ];
  }
}
