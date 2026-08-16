import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/skill_level_engine.dart';

/// Drop this anywhere a user's title needs to show — Home header,
/// Profile header, Leaderboard rows, Competition Results.
///
/// Usage:
/// ```dart
/// LevelTitleBadge(level: profile.level)
/// // or, once you're tracking lifetime XP directly:
/// LevelTitleBadge.fromXp(profile.xp)
/// ```
class LevelTitleBadge extends StatelessWidget {
  final SkillLevelInfo info;
  final bool compact;
  final bool showLevelNumber;

  const LevelTitleBadge({super.key, required this.info, this.compact = false, this.showLevelNumber = true});

  factory LevelTitleBadge.fromLevel(int level, {bool compact = false, bool showLevelNumber = true}) {
    return LevelTitleBadge(info: SkillLevelInfo.fromLevel(level), compact: compact, showLevelNumber: showLevelNumber);
  }

  factory LevelTitleBadge.fromXp(int totalXp, {bool compact = false, bool showLevelNumber = true}) {
    return LevelTitleBadge(info: SkillLevelInfo.fromTotalXp(totalXp), compact: compact, showLevelNumber: showLevelNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 13, vertical: compact ? 4 : 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold.withOpacity(0.18), AppColors.primary.withOpacity(0.14)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.gold.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(info.emoji, style: TextStyle(fontSize: compact ? 12 : 14)),
          SizedBox(width: compact ? 4 : 6),
          Text(
            info.title,
            style: TextStyle(
              fontSize: compact ? 11 : 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.1,
            ),
          ),
          if (showLevelNumber) ...[
            SizedBox(width: compact ? 4 : 6),
            Text(
              'Lv.${info.level}',
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
