import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StepBar extends StatelessWidget {
  final int step; // number of completed steps out of 2
  const StepBar({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(2, (i) {
        final active = i < step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == 0 ? 8 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
