import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/competition_model.dart';
import 'countdown_timer.dart';
import 'pressable_scale.dart';

/// Card used across the Competition Hub for Featured / Daily / Weekly /
/// Monthly sections. Shows banner, category, difficulty, reward,
/// participants, time left, status, and a Join button.
class CompetitionCard extends StatelessWidget {
  final CompetitionModel competition;
  final VoidCallback onTap;
  final VoidCallback onJoin;
  final bool large;

  const CompetitionCard({
    super.key,
    required this.competition,
    required this.onTap,
    required this.onJoin,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = competition;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: large ? double.infinity : 250,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              height: large ? 120 : 92,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: c.bannerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: Icon(c.bannerIcon, size: large ? 100 : 76, color: Colors.black.withOpacity(0.15)),
                  ),
                  Positioned(
                    top: 10,
                    left: 12,
                    child: _StatusChip(status: c.status),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 10,
                    right: 12,
                    child: Text(
                      c.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: large ? 17 : 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withOpacity(0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Pill(text: c.category, color: AppColors.blue),
                      const SizedBox(width: 6),
                      _Pill(text: c.difficulty.label, color: c.difficulty.color),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text('${c.xpReward} XP', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      const Icon(Icons.monetization_on_rounded, size: 14, color: AppColors.gold),
                      const SizedBox(width: 3),
                      Text('${c.coinReward}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.groups_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text('${c.participants}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: c.status == CompetitionStatus.ended
                            ? const Text('Competition ended', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600))
                            : CountdownTimer(target: c.endsAt, compact: true),
                      ),
                      PressableScale(
                        onTap: c.joined || c.status == CompetitionStatus.ended ? null : onJoin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: c.joined ? null : AppColors.primaryGradient,
                            color: c.joined ? AppColors.surfaceElevated : null,
                            borderRadius: BorderRadius.circular(999),
                            border: c.joined ? Border.all(color: AppColors.primary) : null,
                          ),
                          child: Text(
                            c.joined ? 'Joined ✓' : 'Join',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: c.joined ? AppColors.primary : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final CompetitionStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: status.color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(status.label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
