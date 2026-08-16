import 'package:flutter/material.dart';

enum NotificationGroup { today, thisWeek, earlier }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final DateTime time;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.time,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        message: message,
        icon: icon,
        color: color,
        time: time,
        read: read ?? this.read,
      );

  NotificationGroup get group {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inHours < 20 && time.day == now.day) return NotificationGroup.today;
    if (diff.inDays < 7) return NotificationGroup.thisWeek;
    return NotificationGroup.earlier;
  }
}

/// Dummy notification center — grouped by recency, with unread tracking.
/// A real push-notification pipeline can populate the same model later.
class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.read).length;

  NotificationProvider() {
    _notifications = _seed();
  }

  void markRead(String id) {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i == -1 || _notifications[i].read) return;
    _notifications[i] = _notifications[i].copyWith(read: true);
    notifyListeners();
  }

  void markAllRead() {
    _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
  }

  List<AppNotification> _seed() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        title: 'Level Up!',
        message: "You've reached a new title on your Skill Journey.",
        icon: Icons.military_tech_rounded,
        color: Colors.amber,
        time: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'n2',
        title: 'Mission reward ready',
        message: 'Your daily mission is complete — tap to claim XP and coins.',
        icon: Icons.checklist_rounded,
        color: Colors.greenAccent,
        time: now.subtract(const Duration(hours: 5)),
      ),
      AppNotification(
        id: 'n3',
        title: 'New comment on your post',
        message: 'ArjunCodes replied to your Programming post.',
        icon: Icons.chat_bubble_rounded,
        color: Colors.blueAccent,
        time: now.subtract(const Duration(hours: 9)),
        read: true,
      ),
      AppNotification(
        id: 'n4',
        title: 'Competition starting soon',
        message: 'Weekly Build-Off closes in 24 hours — you\'re still in the running.',
        icon: Icons.emoji_events_rounded,
        color: Colors.deepOrangeAccent,
        time: now.subtract(const Duration(days: 2)),
      ),
      AppNotification(
        id: 'n5',
        title: 'New badge unlocked',
        message: 'You earned the "Week Warrior" badge for a 7-day streak.',
        icon: Icons.workspace_premium_rounded,
        color: Colors.purpleAccent,
        time: now.subtract(const Duration(days: 4)),
        read: true,
      ),
      AppNotification(
        id: 'n6',
        title: 'Welcome to SkillVerse',
        message: 'Complete your profile to unlock personalized recommendations.',
        icon: Icons.waving_hand_rounded,
        color: Colors.cyanAccent,
        time: now.subtract(const Duration(days: 12)),
        read: true,
      ),
    ];
  }
}
