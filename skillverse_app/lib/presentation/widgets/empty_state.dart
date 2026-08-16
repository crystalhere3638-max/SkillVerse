import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.primary.withOpacity(0.13), Colors.transparent]),
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 28),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
