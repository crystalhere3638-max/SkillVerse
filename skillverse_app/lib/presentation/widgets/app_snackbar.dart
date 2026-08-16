import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppSnackbar {
  AppSnackbar._();

  static void error(BuildContext context, String message) {
    _show(context, message, AppColors.error, Icons.error_outline);
  }

  static void success(BuildContext context, String message) {
    _show(context, message, AppColors.primary, Icons.check_circle_outline);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, AppColors.blue, Icons.info_outline);
  }

  static void _show(BuildContext context, String message, Color accent, IconData icon) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
