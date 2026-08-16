import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_ago.dart';
import '../../data/models/comment_model.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isOwn;
  final bool isReply;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CommentTile({
    super.key,
    required this.comment,
    required this.isOwn,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 8), child: child),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: isReply ? 34 : 0, bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isReply ? 28 : 34,
              height: isReply ? 28 : 34,
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: isReply ? 11 : 13, fontWeight: FontWeight.w800, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(comment.authorName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                            const SizedBox(width: 6),
                            Text(comment.authorLevel,
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(comment.text, style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(timeAgo(comment.createdAt), style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                      if (comment.isEdited) ...[
                        const SizedBox(width: 6),
                        const Text('· edited', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                      ],
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onReply,
                        child: const Text('Reply', style: TextStyle(fontSize: 10.5, color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                      if (isOwn) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: onEdit,
                          child: const Text('Edit', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: onDelete,
                          child: const Text('Delete', style: TextStyle(fontSize: 10.5, color: AppColors.error, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
