import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Standard error state for any screen that loads data. Pairs with
/// [EmptyState] and skeleton loaders so every screen follows the same
/// loading → content / empty / error pattern.
class ErrorStateView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const ErrorStateView({
    super.key,
    this.title = 'Something went wrong',
    this.message = "We couldn't load this right now. Please try again.",
    required this.onRetry,
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withOpacity(0.12),
                border: Border.all(color: AppColors.error.withOpacity(0.35)),
              ),
              child: const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 26),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 18),
            SizedBox(
              height: 44, // comfortable 44pt touch target
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: const BorderSide(color: AppColors.divider)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
