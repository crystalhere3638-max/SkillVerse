import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/skill_level_engine.dart';

/// "Skill Journey" — shows current level/title, XP progress toward the
/// next title, and a timeline of every tier (past, current, locked).
class SkillJourneyScreen extends StatelessWidget {
  final int totalXp;

  const SkillJourneyScreen({super.key, required this.totalXp});

  @override
  Widget build(BuildContext context) {
    final info = SkillLevelInfo.fromTotalXp(totalXp);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Skill Journey', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _HeroCard(info: info),
          const SizedBox(height: 28),
          const Text('Journey Timeline', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 14),
          _Timeline(currentLevel: info.level),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final SkillLevelInfo info;
  const _HeroCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.gold, AppColors.orange]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.35), blurRadius: 20)],
            ),
            child: Center(child: Text(info.emoji, style: const TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 14),
          Text('Level ${info.level}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(info.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gold)),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: info.progress,
              minHeight: 10,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${info.xpIntoLevel} / ${info.xpForThisLevel} XP',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              Text('Level ${info.level + 1}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 18),
          if (info.nextTier != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Text(info.nextTier!.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Next Title: ${info.nextTier!.title}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('${info.levelsUntilNextTier} level${info.levelsUntilNextTier == 1 ? '' : 's'} to go',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withOpacity(0.35)),
              ),
              child: const Text("You've reached the highest title — Legend 🔥",
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.gold)),
            ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final int currentLevel;
  const _Timeline({required this.currentLevel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(kSkillTiers.length, (i) {
        final tier = kSkillTiers[i];
        final isLast = i == kSkillTiers.length - 1;
        final unlocked = currentLevel >= tier.minLevel;
        final isCurrent = tier.contains(currentLevel);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unlocked ? AppColors.gold.withOpacity(0.16) : AppColors.surfaceSunken,
                      border: Border.all(
                        color: isCurrent ? AppColors.gold : (unlocked ? AppColors.gold.withOpacity(0.5) : AppColors.divider),
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: unlocked
                          ? Text(tier.emoji, style: const TextStyle(fontSize: 18))
                          : const Icon(Icons.lock_rounded, size: 16, color: AppColors.textMuted),
                    ),
                  ),
                  if (!isLast) Expanded(child: Container(width: 2, color: unlocked ? AppColors.gold.withOpacity(0.4) : AppColors.divider)),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 26, top: 4),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.gold.withOpacity(0.08) : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isCurrent ? AppColors.gold.withOpacity(0.45) : AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tier.title,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: unlocked ? Colors.white : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tier.maxLevel != null ? 'Level ${tier.minLevel}–${tier.maxLevel}' : 'Level ${tier.minLevel}+',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(999)),
                            child: const Text('YOU ARE HERE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black)),
                          )
                        else if (!unlocked)
                          const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
