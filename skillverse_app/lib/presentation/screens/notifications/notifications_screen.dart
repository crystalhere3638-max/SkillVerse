import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_ago.dart';
import '../../../providers/notification_provider.dart';
import '../../widgets/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final groups = <NotificationGroup, List<AppNotification>>{};
    for (final n in provider.notifications) {
      groups.putIfAbsent(n.group, () => []).add(n);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => context.read<NotificationProvider>().markAllRead(),
              child: const Text('Mark all read', style: TextStyle(fontSize: 12.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: provider.notifications.isEmpty
          ? const EmptyState(icon: Icons.notifications_none_rounded, title: 'No notifications yet', message: 'We\'ll let you know when something happens.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              children: [
                for (final group in [NotificationGroup.today, NotificationGroup.thisWeek, NotificationGroup.earlier])
                  if (groups[group]?.isNotEmpty ?? false) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, top: 14),
                      child: Text(_groupLabel(group), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    ),
                    ...groups[group]!.map((n) => _NotificationTile(notification: n)),
                  ],
              ],
            ),
    );
  }

  String _groupLabel(NotificationGroup g) {
    switch (g) {
      case NotificationGroup.today:
        return 'Today';
      case NotificationGroup.thisWeek:
        return 'This Week';
      case NotificationGroup.earlier:
        return 'Earlier';
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.read<NotificationProvider>().markRead(n.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.read ? AppColors.surface : AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: n.read ? AppColors.divider : AppColors.primary.withOpacity(0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: n.color.withOpacity(0.16), shape: BoxShape.circle),
              child: Icon(n.icon, color: n.color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(n.message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                  const SizedBox(height: 6),
                  Text(timeAgo(n.time), style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (!n.read)
              Container(margin: const EdgeInsets.only(top: 4), width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}
