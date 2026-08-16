import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_ago.dart';
import '../../../data/models/badge_model.dart';
import '../../../providers/badge_provider.dart';

class BadgeGalleryScreen extends StatelessWidget {
  const BadgeGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BadgeProvider>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Badge Collection', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 20),
                const SizedBox(width: 10),
                Text('${provider.unlocked.length}/${provider.badges.length} badges unlocked',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive column count: compact phones, regular phones,
              // and tablets all get a comfortable tile size.
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 700 ? 5 : (width >= 480 ? 4 : 3);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.badges.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.82),
                itemBuilder: (_, i) => _BadgeTile(badge: provider.badges[i]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeModel badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final color = badge.unlocked ? badge.tier.color : AppColors.textMuted;
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => BadgeDetailSheet(badge: badge),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: color.withOpacity(badge.unlocked ? 0.16 : 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(badge.unlocked ? 0.6 : 0.25), width: 1.5),
            ),
            child: Icon(badge.unlocked ? badge.icon : Icons.lock_outline_rounded, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badge.unlocked ? Colors.white : AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet with full badge detail — requirement, tier, unlock date.
class BadgeDetailSheet extends StatelessWidget {
  final BadgeModel badge;
  const BadgeDetailSheet({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final color = badge.unlocked ? badge.tier.color : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 34),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(color: color.withOpacity(0.16), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.6), width: 2)),
            child: Icon(badge.unlocked ? badge.icon : Icons.lock_outline_rounded, color: color, size: 38),
          ),
          const SizedBox(height: 16),
          Text(badge.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(999)),
            child: Text(badge.tier.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
          const SizedBox(height: 14),
          Text(badge.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.flag_outlined, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(child: Text(badge.requirement, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              ],
            ),
          ),
          if (badge.unlocked && badge.unlockedAt != null) ...[
            const SizedBox(height: 10),
            Text('Unlocked ${timeAgo(badge.unlockedAt!)}', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}
