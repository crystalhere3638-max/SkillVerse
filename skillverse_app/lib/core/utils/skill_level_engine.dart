/// ==========================================================
/// SKILL JOURNEY — level & title engine
/// ==========================================================
/// Single source of truth for turning a user's total XP into a
/// level, a meaningful title, and everything the UI needs to
/// render progress (Home, Profile, Leaderboard, Competition
/// Results, and the dedicated Skill Journey screen).
///
/// Design notes:
/// - `xp` on AppUser is treated as *lifetime total XP*. Level is
///   always derived from it, so it can never drift out of sync.
/// - The XP curve is deliberately simple (linearly increasing
///   requirement per level) so it's easy to tune later without
///   touching any UI code — just edit [_xpToReachNextLevel].
library skill_level_engine;

class SkillTier {
  final String title;
  final String emoji;
  final int minLevel;
  final int? maxLevel; // null = open-ended (Legend)

  const SkillTier({
    required this.title,
    required this.emoji,
    required this.minLevel,
    this.maxLevel,
  });

  bool contains(int level) => level >= minLevel && (maxLevel == null || level <= maxLevel!);

  String get label => '$emoji $title';
}

/// Default progression, exactly as specified by product:
/// 1–4 Beginner · 5–9 Explorer · 10–19 Skilled · 20–34 Expert ·
/// 35–49 Master · 50+ Legend.
const List<SkillTier> kSkillTiers = [
  SkillTier(title: 'Beginner', emoji: '🌱', minLevel: 1, maxLevel: 4),
  SkillTier(title: 'Explorer', emoji: '🧭', minLevel: 5, maxLevel: 9),
  SkillTier(title: 'Skilled', emoji: '⚡', minLevel: 10, maxLevel: 19),
  SkillTier(title: 'Expert', emoji: '🏆', minLevel: 20, maxLevel: 34),
  SkillTier(title: 'Master', emoji: '👑', minLevel: 35, maxLevel: 49),
  SkillTier(title: 'Legend', emoji: '🔥', minLevel: 50, maxLevel: null),
];

SkillTier tierForLevel(int level) {
  for (final tier in kSkillTiers) {
    if (tier.contains(level)) return tier;
  }
  return kSkillTiers.last;
}

/// XP required to go from [level] to [level + 1].
/// Rises steadily so higher levels feel earned, not just handed out.
int xpToReachNextLevel(int level) => 100 + (level - 1) * 25;

/// Total cumulative XP required to *reach* [level] (level 1 = 0 XP).
int cumulativeXpForLevel(int level) {
  var total = 0;
  for (var l = 1; l < level; l++) {
    total += xpToReachNextLevel(l);
  }
  return total;
}

/// Everything the UI needs to render one moment of a user's journey.
class SkillLevelInfo {
  final int level;
  final int totalXp;
  final SkillTier tier;
  final int xpIntoLevel;
  final int xpForThisLevel;
  final double progress; // 0..1 toward next level
  final SkillTier? nextTier; // null only for max tier (Legend)
  final int? levelsUntilNextTier;

  const SkillLevelInfo({
    required this.level,
    required this.totalXp,
    required this.tier,
    required this.xpIntoLevel,
    required this.xpForThisLevel,
    required this.progress,
    required this.nextTier,
    required this.levelsUntilNextTier,
  });

  String get title => tier.title;
  String get emoji => tier.emoji;
  String get label => tier.label;

  factory SkillLevelInfo.fromTotalXp(int totalXp) {
    var level = 1;
    var remaining = totalXp;
    while (true) {
      final need = xpToReachNextLevel(level);
      if (remaining < need) break;
      remaining -= need;
      level++;
      if (level > 999) break; // safety valve
    }
    final xpForThisLevel = xpToReachNextLevel(level);
    final tier = tierForLevel(level);
    final next = kSkillTiers.firstWhere(
      (t) => t.minLevel > tier.minLevel,
      orElse: () => tier,
    );
    final hasNext = next.minLevel > tier.minLevel;

    return SkillLevelInfo(
      level: level,
      totalXp: totalXp,
      tier: tier,
      xpIntoLevel: remaining,
      xpForThisLevel: xpForThisLevel,
      progress: xpForThisLevel == 0 ? 0 : (remaining / xpForThisLevel).clamp(0, 1).toDouble(),
      nextTier: hasNext ? next : null,
      levelsUntilNextTier: hasNext ? (next.minLevel - level) : null,
    );
  }

  /// Convenience for places that only ever had `level` (e.g. AppUser.level)
  /// and haven't migrated to total-XP tracking yet.
  factory SkillLevelInfo.fromLevel(int level) {
    return SkillLevelInfo.fromTotalXp(cumulativeXpForLevel(level));
  }
}
