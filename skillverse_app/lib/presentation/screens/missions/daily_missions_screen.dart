import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/mission_model.dart';
import '../../../providers/mission_provider.dart';
import '../../widgets/pressable_scale.dart';

class DailyMissionsScreen extends StatelessWidget {
  const DailyMissionsScreen({super.key});

  Future<void> _handleClaim(BuildContext context, MissionModel mission) async {
    final reward = context.read<MissionProvider>().claim(mission.id);
    if (reward == null) return;
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Mission complete',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => _MissionCompleteDialog(mission: mission, xp: reward.$1, coins: reward.$2),
      transitionBuilder: (_, anim, __, child) => Transform.scale(
        scale: 0.75 + 0.25 * Curves.easeOutBack.transform(anim.value),
        child: Opacity(opacity: anim.value.clamp(0, 1), child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MissionProvider>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Daily Missions', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.16), AppColors.surfaceElevated]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.checklist_rounded, color: AppColors.primary, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${provider.completedCount}/3 missions complete',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 2),
                      const Text('Finish all three for a fresh streak boost tomorrow',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          ...provider.missions.map((m) => _MissionCard(mission: m, onClaim: () => _handleClaim(context, m))),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final MissionModel mission;
  final VoidCallback onClaim;
  const _MissionCard({required this.mission, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final done = mission.isCompleted;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: mission.claimed ? AppColors.primary.withOpacity(0.4) : AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (mission.claimed ? AppColors.primary : AppColors.blue).withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(mission.claimed ? Icons.check_rounded : mission.icon, color: mission.claimed ? AppColors.primary : AppColors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mission.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(mission.description, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: mission.progressFraction,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(mission.claimed ? AppColors.primary : AppColors.blue),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('${mission.progress}/${mission.target}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              const Icon(Icons.bolt_rounded, size: 13, color: AppColors.primary),
              Text(' +${mission.xpReward} XP', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              const Icon(Icons.monetization_on_rounded, size: 13, color: AppColors.gold),
              Text(' +${mission.coinReward}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const Spacer(),
              if (mission.claimed)
                const Text('Claimed ✓', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary))
              else
                PressableScale(
                  onTap: done ? onClaim : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: done ? AppColors.primaryGradient : null,
                      color: done ? null : AppColors.surfaceSunken,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      done ? 'Claim' : 'In Progress',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: done ? Colors.black : AppColors.textMuted),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionCompleteDialog extends StatelessWidget {
  final MissionModel mission;
  final int xp;
  final int coins;
  const _MissionCompleteDialog({required this.mission, required this.xp, required this.coins});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 36, spreadRadius: 2)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.black, size: 36),
              ),
              const SizedBox(height: 14),
              const Text('Mission Complete!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text(mission.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _rewardChip(Icons.bolt_rounded, '+$xp XP', AppColors.primary),
                  const SizedBox(width: 10),
                  _rewardChip(Icons.monetization_on_rounded, '+$coins Coins', AppColors.gold),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Nice!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rewardChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(0.4))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
