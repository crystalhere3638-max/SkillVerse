import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 50)],
              ),
              child: const Icon(Icons.diamond_outlined, color: Colors.black, size: 42),
            ),
            const SizedBox(height: 22),
            const Text(
              'SkillVerse',
              style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
            ),
            const SizedBox(height: 8),
            const Text(
              'Learn. Compete. Earn. Teach.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
