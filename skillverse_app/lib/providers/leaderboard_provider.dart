import 'package:flutter/material.dart';
import '../core/utils/skill_level_engine.dart';
import '../data/models/leaderboard_entry.dart';

enum LeaderboardRange { daily, weekly, monthly, allTime }

class LeaderboardProvider extends ChangeNotifier {
  LeaderboardRange _range = LeaderboardRange.weekly;
  LeaderboardRange get range => _range;

  void setRange(LeaderboardRange range) {
    if (_range == range) return;
    _range = range;
    notifyListeners();
  }

  List<LeaderboardEntry> get entries => _mockFor(_range);

  static const _names = [
    'ArjunCodes', 'PixelPriya', 'DevRohanX', 'ByteQueen', 'InkedIsha',
    'ShipItSam', 'NehaBuilds', 'PromptPranav', 'LegendaryLata', 'MaxMastery',
    'SkillSiddharth', 'CreativeKabir', 'You',
  ];

  List<LeaderboardEntry> _mockFor(LeaderboardRange range) {
    // Deterministic-but-varied mock scores per range so switching tabs
    // visibly reorders the board without needing a backend yet.
    final seedMultiplier = switch (range) {
      LeaderboardRange.daily => 3,
      LeaderboardRange.weekly => 11,
      LeaderboardRange.monthly => 37,
      LeaderboardRange.allTime => 121,
    };

    final scored = <LeaderboardEntry>[];
    for (var i = 0; i < _names.length; i++) {
      final base = (_names[i].hashCode.abs() % 500) + seedMultiplier * (17 - i);
      final level = 8 + ((base ~/ 40) % 45);
      scored.add(LeaderboardEntry(
        rank: 0,
        username: _names[i],
        level: level,
        title: tierForLevel(level).title,
        score: base,
        isCurrentUser: _names[i] == 'You',
      ));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));

    return List.generate(scored.length, (i) {
      final e = scored[i];
      return LeaderboardEntry(
        rank: i + 1,
        username: e.username,
        level: e.level,
        title: e.title,
        score: e.score,
        isCurrentUser: e.isCurrentUser,
      );
    });
  }
}
