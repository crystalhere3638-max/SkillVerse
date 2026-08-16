import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class _ShareOption {
  final IconData icon;
  final String label;
  final Color color;
  const _ShareOption(this.icon, this.label, this.color);
}

const _shareOptions = [
  _ShareOption(Icons.link_rounded, 'Copy Link', AppColors.primary),
  _ShareOption(Icons.chat_bubble_rounded, 'WhatsApp', Color(0xFF25D366)),
  _ShareOption(Icons.telegram_rounded, 'Telegram', Color(0xFF29A9EA)),
  _ShareOption(Icons.mail_rounded, 'Email', AppColors.blue),
  _ShareOption(Icons.more_horiz_rounded, 'More', AppColors.textSecondary),
];

/// Visual-only share sheet — sharing isn't wired to real targets yet
/// (see [ShareService]); this establishes the UI/UX so hooking up
/// `share_plus` later is a drop-in change.
class ShareSheet extends StatelessWidget {
  final VoidCallback? onShared;
  const ShareSheet({super.key, this.onShared});

  /// [onShared] is optional and defaults to null so every existing
  /// call site (e.g. the post feed) behaves exactly as before.
  static Future<void> show(BuildContext context, {VoidCallback? onShared}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareSheet(onShared: onShared),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24, top: 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4)),
          ),
          const Text('Share Post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Sharing is coming soon', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _shareOptions.map((opt) {
                return GestureDetector(
                  onTap: () {
                    onShared?.call();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(
                        content: Text('Sharing will be available in a future update'),
                        duration: Duration(seconds: 2),
                      ));
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: opt.color.withOpacity(0.15), shape: BoxShape.circle),
                        child: Icon(opt.icon, color: opt.color, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(opt.label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
