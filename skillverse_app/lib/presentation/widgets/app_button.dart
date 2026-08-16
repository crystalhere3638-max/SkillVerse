import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum AppButtonVariant { primary, outlined }

/// Shared button used across auth + onboarding. Handles the
/// "disable while loading" + "prevent double taps" rules in one
/// place instead of repeating them per screen.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final Widget? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
  });

  bool get _disabled => isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(label),
            ],
          );

    if (variant == AppButtonVariant.outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _disabled ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                )
              : child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: AppColors.primary.withOpacity(0.35),
          disabledForegroundColor: Colors.black.withOpacity(0.4),
        ),
        child: child,
      ),
    );
  }
}
