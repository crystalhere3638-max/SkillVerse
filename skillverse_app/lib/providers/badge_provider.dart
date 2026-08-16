import 'package:flutter/material.dart';
import '../data/models/badge_model.dart';

class BadgeProvider extends ChangeNotifier {
  List<BadgeModel> _badges = [];
  List<BadgeModel> get badges => _badges;

  List<BadgeModel> get unlocked => _badges.where((b) => b.unlocked).toList();
  List<BadgeModel> get locked => _badges.where((b) => !b.unlocked).toList();

  BadgeProvider() {
    _badges = _seedBadges();
  }

  List<BadgeModel> _seedBadges() {
    final now = DateTime.now();
    return [
      BadgeModel(
        id: 'badge_first_post',
        name: 'First Steps',
        description: 'Published your very first post on SkillVerse',
        icon: Icons.flag_rounded,
        tier: BadgeTier.bronze,
        requirement: 'Publish 1 post',
        unlocked: true,
        unlockedAt: now.subtract(const Duration(days: 40)),
      ),
      BadgeModel(
        id: 'badge_streak_7',
        name: 'Week Warrior',
        description: 'Kept a 7-day streak alive',
        icon: Icons.local_fire_department_rounded,
        tier: BadgeTier.silver,
        requirement: 'Maintain a 7-day streak',
        unlocked: true,
        unlockedAt: now.subtract(const Duration(days: 12)),
      ),
      BadgeModel(
        id: 'badge_competition_win',
        name: 'Champion',
        description: 'Won 1st place in any competition',
        icon: Icons.emoji_events_rounded,
        tier: BadgeTier.gold,
        requirement: 'Win a competition',
        unlocked: false,
      ),
      BadgeModel(
        id: 'badge_100_likes',
        name: 'Crowd Favorite',
        description: 'Received 100 total likes across your posts',
        icon: Icons.favorite_rounded,
        tier: BadgeTier.silver,
        requirement: 'Get 100 likes',
        unlocked: true,
        unlockedAt: now.subtract(const Duration(days: 5)),
      ),
      BadgeModel(
        id: 'badge_level_20',
        name: 'Expert Tier',
        description: 'Reached Level 20 — Expert title unlocked',
        icon: Icons.trending_up_rounded,
        tier: BadgeTier.gold,
        requirement: 'Reach Level 20',
        unlocked: false,
      ),
      BadgeModel(
        id: 'badge_mentor',
        name: 'Mentor Spirit',
        description: 'Helped 10 other learners via comments',
        icon: Icons.volunteer_activism_rounded,
        tier: BadgeTier.silver,
        requirement: 'Leave 10 helpful comments',
        unlocked: false,
      ),
      BadgeModel(
        id: 'badge_legend',
        name: 'Living Legend',
        description: 'Reached the Legend title — Level 50+',
        icon: Icons.whatshot_rounded,
        tier: BadgeTier.platinum,
        requirement: 'Reach Level 50',
        unlocked: false,
      ),
      BadgeModel(
        id: 'badge_monthly_top10',
        name: 'Top 10 Finisher',
        description: 'Finished in the Top 10 of a monthly competition',
        icon: Icons.military_tech_rounded,
        tier: BadgeTier.gold,
        requirement: 'Top 10 in Creator of the Month',
        unlocked: false,
      ),
    ];
  }
}
