import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PostCardSkeleton extends StatefulWidget {
  const PostCardSkeleton({super.key});

  @override
  State<PostCardSkeleton> createState() => _PostCardSkeletonState();
}

class _PostCardSkeletonState extends State<PostCardSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.35 + 0.25 * (0.5 - (_controller.value - 0.5).abs()) * 2;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _block(40, 40, radius: 20, opacity: opacity),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _block(90, 11, opacity: opacity),
                        const SizedBox(height: 6),
                        _block(60, 9, opacity: opacity),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _block(double.infinity, 11, opacity: opacity),
              const SizedBox(height: 6),
              _block(180, 11, opacity: opacity),
            ],
          ),
        );
      },
    );
  }

  Widget _block(double width, double height, {double radius = 6, required double opacity}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.divider.withOpacity(opacity),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
