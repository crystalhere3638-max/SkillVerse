import 'package:flutter/material.dart';
import '../../core/constants/post_categories.dart';
import '../../core/theme/app_colors.dart';

class CategoryFilterBar extends StatelessWidget {
  final String? selected; // null == "All"
  final ValueChanged<String?> onChanged;
  const CategoryFilterBar({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: postCategories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final active = selected == null;
            return _Chip(label: 'All', active: active, color: AppColors.primary, onTap: () => onChanged(null));
          }
          final c = postCategories[index - 1];
          final active = selected == c.name;
          return _Chip(label: c.name, active: active, color: c.accent, icon: c.icon, onTap: () => onChanged(c.name));
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.color, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.16) : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? color : AppColors.divider, width: active ? 1.5 : 1),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: active ? color : AppColors.textSecondary),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
