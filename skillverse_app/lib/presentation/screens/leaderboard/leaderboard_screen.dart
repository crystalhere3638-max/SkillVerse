import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/leaderboard_entry.dart';
import '../../../providers/leaderboard_provider.dart';
import '../../widgets/level_title_badge.dart';
import '../../../core/utils/skill_level_engine.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static const _tabs = [
    (LeaderboardRange.daily, 'Daily'),
    (LeaderboardRange.weekly, 'Weekly'),
    (LeaderboardRange.monthly, 'Monthly'),
    (LeaderboardRange.allTime, 'All Time'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeaderboardProvider>();
    final entries = provider.entries;
    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: _tabs.map((t) {
                final selected = provider.range == t.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.read<LeaderboardProvider>().setRange(t.$1),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
                      ),
                      child: Text(
                        t.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.black : AppColors.textSecondary),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (top3.length == 3) _Podium(top3: top3),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              itemCount: rest.length,
              itemBuilder: (_, i) => _RankRow(entry: rest[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top3;
  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    final first = top3[0], second = top3[1], third = top3[2];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _PodiumPlace(entry: second, height: 96, color: const Color(0xFFC0C0C0))),
          const SizedBox(width: 8),
          Expanded(child: _PodiumPlace(entry: first, height: 122, color: AppColors.gold, crown: true)),
          const SizedBox(width: 8),
          Expanded(child: _PodiumPlace(entry: third, height: 78, color: const Color(0xFFCD7F32))),
        ],
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final Color color;
  final bool crown;
  const _PodiumPlace({required this.entry, required this.height, required this.color, this.crown = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (crown) const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 22),
        const SizedBox(height: 4),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: color.withOpacity(0.18), shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
          child: Center(
            child: Text(entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ),
        ),
        const SizedBox(height: 6),
        Text(entry.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
        Text('${entry.score} pts', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.16),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          child: Text('#${entry.rank}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;
  const _RankRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: entry.isCurrentUser ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: entry.isCurrentUser ? AppColors.primary.withOpacity(0.5) : AppColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('#${entry.rank}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(entry.username, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(width: 8),
                LevelTitleBadge(info: SkillLevelInfo.fromLevel(entry.level), compact: true, showLevelNumber: false),
              ],
            ),
          ),
          Text('${entry.score} pts', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }
}
