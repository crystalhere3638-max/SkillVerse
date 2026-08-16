import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String appVersion = '1.0.0 (Beta)';

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          const _SectionLabel('Appearance'),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Dark Theme',
            subtitle: 'SkillVerse is designed dark-first for now',
            trailing: Switch(value: true, onChanged: null, activeColor: AppColors.primary),
          ),
          const SizedBox(height: 22),
          const _SectionLabel('Notifications'),
          _SettingsTile(
            icon: Icons.notifications_active_rounded,
            title: 'Push Notifications',
            subtitle: 'Mission reminders, level-ups, and competition alerts',
            trailing: Switch(
              value: settings.notificationsEnabled,
              onChanged: settings.loaded ? (v) => context.read<SettingsProvider>().setNotificationsEnabled(v) : null,
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 22),
          const _SectionLabel('Support & Info'),
          _SettingsTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () => _showInfoSheet(context, 'Privacy Policy', _privacyText)),
          _SettingsTile(icon: Icons.help_outline_rounded, title: 'Help & Support', onTap: () => _showInfoSheet(context, 'Help & Support', _helpText)),
          _SettingsTile(icon: Icons.info_outline_rounded, title: 'About SkillVerse', onTap: () => _showInfoSheet(context, 'About SkillVerse', _aboutText)),
          const SizedBox(height: 22),
          Center(
            child: Text('SkillVerse v$appVersion', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  void _showInfoSheet(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 12),
            Text(body, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
          ],
        ),
      ),
    );
  }

  static const _privacyText =
      'SkillVerse stores your profile, posts, and activity locally and (once connected) in Firebase, used only to power your learning journey — never sold to third parties.';
  static const _helpText = 'Need a hand? Reach out any time at support@skillverse.app and we\'ll get back to you within 24 hours.';
  static const _aboutText = 'SkillVerse is a skill-learning and competition platform — learn, compete, and grow with a community built around your craft.';
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.title, this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(minHeight: 56), // comfortable touch target
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 17, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing! else if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
