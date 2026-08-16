import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PublishSuccessOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const PublishSuccessOverlay({super.key, required this.onDone});

  @override
  State<PublishSuccessOverlay> createState() => _PublishSuccessOverlayState();
}

class _PublishSuccessOverlayState extends State<PublishSuccessOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.65),
      alignment: Alignment.center,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.black, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Post published!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('It\'s now live on your feed', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
