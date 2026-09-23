import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/post_categories.dart';
import '../../core/services/share_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/media_source.dart';
import '../../core/utils/time_ago.dart';
import '../../data/models/post_model.dart';
import '../../providers/post_provider.dart';
import '../../data/services/firestore_post_service.dart';
import 'comment_sheet.dart';
import 'double_tap_like.dart';
import 'report_sheet.dart';
import 'share_sheet.dart';
import 'video/feed_video_player.dart';

 class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  static  final _shareService = ShareService();
  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4))),
              Consumer<PostProvider>(
                builder: (context, provider, _) {
                  final current = provider.postById(post.id) ?? post;
                  return _sheetOption(
                    sheetCtx,
                    current.savedByMe ? Icons.bookmark : Icons.bookmark_border,
                    current.savedByMe ? 'Remove from Saved' : 'Save Post',
                    () => provider.toggleSave(post.id),
                  );
                },
              ),
              _sheetOption(sheetCtx, Icons.share_outlined, 'Share', () => _shareService.sharePost(post)),
              _sheetOption(sheetCtx, Icons.flag_outlined, 'Report', () => ReportSheet.show(context, post.id), danger: true),
              _sheetOption(sheetCtx, Icons.link, 'Copy Link', () => _copyLink(context)),
              if (post.authorId == _currentUid)
                _sheetOption(sheetCtx, Icons.delete_outline, 'Delete Post',
                    () => _confirmDelete(context, post.id), danger: true),
            ],
          ),
        ),
      ),
    );
  }

  void _copyLink(BuildContext context) {
    final link = _shareService.buildShareLink(post);
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Link copied to clipboard'), duration: Duration(seconds: 2)));
  }
   void _confirmDelete(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  try {
                    await context.read<FirestorePostService>().deletePost(postId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post deleted')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Delete failed: $e')),
                      );
                    }
                  }
                },
                child: const Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
        ],
      ),
    );
   }

  Widget _sheetOption(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    final color = danger ? AppColors.error : Colors.white;
    return ListTile(
      leading: Icon(icon, color: danger ? AppColors.error : AppColors.textSecondary, size: 19),
      title: Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = categoryColor(post.category);

    return Consumer<PostProvider>(
      builder: (context, provider, _) {
        // Always read the freshest copy so likes/comments/saves reflect
        // instantly even if this exact widget instance is reused.
        final current = provider.postById(post.id) ?? post;

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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        current.authorName.isNotEmpty ? current.authorName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(current.authorName,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _LevelBadge(level: current.authorLevel),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(timeAgo(current.createdAt),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
                    child: Text(current.category, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accent)),
                  ),
                ],
              ),

              // Caption + media share one double-tap-to-like zone, like
              // the familiar feed pattern — tapping anywhere here twice
              // likes the post and pops a heart, without interfering
              // with the explicit like/comment/save buttons below.
              DoubleTapLike(
                borderRadius: BorderRadius.circular(14),
                onLike: () => context.read<PostProvider>().likeOnly(post.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (current.caption.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(current.caption, style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.5)),
                    ],
                    if (current.mediaType != PostMediaType.none && current.mediaPath != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: current.mediaType == PostMediaType.image
                            ? (isNetworkMediaPath(current.mediaPath!)
                                ? Image.network(
                                    current.mediaPath!,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) =>
                                        progress == null ? child : _mediaLoading(),
                                    errorBuilder: (_, __, ___) => _mediaFallback(Icons.image_not_supported_outlined),
                                  )
                                : Image.file(
                                    File(current.mediaPath!),
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _mediaFallback(Icons.image_not_supported_outlined),
                                  ))
                            : FeedVideoPlayer(mediaPath: current.mediaPath!),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 8),
              Row(
                children: [
                  _LikeButton(liked: current.likedByMe, likes: current.likes, onTap: () => provider.toggleLike(post.id)),
                  const SizedBox(width: 18),
                  _ActionTap(
                    onTap: () => CommentSheet.show(context, post.id),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 5),
                        Text('${current.commentCount}',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  _ActionTap(
                    onTap: () => _shareService.sharePost(post), 
                    child: const Row(
                      children: [
                        Icon(Icons.share_outlined, size: 15, color: AppColors.textSecondary),
                        SizedBox(width: 5),
                        Text('Share', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _ActionTap(
                    onTap: () => provider.toggleSave(post.id),
                    child: Icon(current.savedByMe ? Icons.bookmark : Icons.bookmark_border,
                        size: 17, color: current.savedByMe ? AppColors.primary : AppColors.textMuted),
                  ),
                  const SizedBox(width: 14),
                  _ActionTap(
                    onTap: () => _showMoreSheet(context),
                    child: const Icon(Icons.more_horiz, size: 18, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mediaFallback(IconData icon) => Container(
        width: double.infinity,
        height: 200,
        color: AppColors.surfaceSunken,
        child: Icon(icon, color: AppColors.textMuted, size: 32),
      );

  Widget _mediaLoading() => Container(
        width: double.infinity,
        height: 200,
        color: AppColors.surfaceSunken,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
        ),
      );
}

class _ActionTap extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _ActionTap({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2), child: child),
    );
  }
}

/// Like button with its own scale-pop animation, independent of the
/// double-tap heart overlay — covers the explicit tap-to-like/unlike
/// interaction with haptic feedback and optimistic UI.
class _LikeButton extends StatefulWidget {
  final bool liked;
  final int likes;
  final VoidCallback onTap;
  const _LikeButton({required this.liked, required this.likes, required this.onTap});

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap(); // optimistic — provider updates state immediately
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return _ActionTap(
      onTap: _handleTap,
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _scale,
            builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
            child: Icon(widget.liked ? Icons.favorite : Icons.favorite_border,
                size: 17, color: widget.liked ? AppColors.error : AppColors.textSecondary),
          ),
          const SizedBox(width: 5),
          Text('${widget.likes}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Small "Lv.N" pill with a medal icon — the required Level Badge.
class _LevelBadge extends StatelessWidget {
  final String level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.military_tech_rounded, size: 10, color: AppColors.gold),
          const SizedBox(width: 3),
          Text(level, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.gold)),
        ],
      ),
    );
  }
}
