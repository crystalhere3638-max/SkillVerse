import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_ago.dart';
import '../../../data/models/activity_model.dart';
import '../../../providers/post_provider.dart';
import '../../widgets/empty_state.dart';

class RecentActivityScreen extends StatelessWidget {
  const RecentActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final log = context.watch<PostProvider>().activityLog;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text('Recent Activity', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: log.isEmpty
          ? const EmptyState(
              icon: Icons.history_rounded,
              title: 'No activity yet',
              message: 'Likes, comments, saves, and posts will show up here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: log.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _ActivityRow(entry: log[i]),
            ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityEntry entry;
  const _ActivityRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(entry.type.icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.type.verb(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text('${entry.postCategory} · ${timeAgo(entry.timestamp)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
