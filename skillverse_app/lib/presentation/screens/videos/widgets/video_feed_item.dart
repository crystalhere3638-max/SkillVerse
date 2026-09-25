import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../data/models/video_post_model.dart';
import '../../../../providers/video_provider.dart';
import '../../../widgets/double_tap_like.dart';
import '../../../widgets/share_sheet.dart';
import 'video_comment_sheet.dart';

/// A single full-screen page in the Videos feed. Plays/pauses itself
/// based on [isActive] rather than polling scroll position — the
/// parent PageView is the single source of truth for which page is
/// centered (see [VideoProvider.activeIndex]).
class VideoFeedItem extends StatefulWidget {
  final VideoPost video;
  final bool isActive;

  const VideoFeedItem({super.key, required this.video, required this.isActive});

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  VideoPlayerController? _controller;
  bool _initializing = false;
  bool _failed = false;
  bool _muted = false;
  bool _showPauseIcon = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _init();
  }

  @override
  void didUpdateWidget(covariant VideoFeedItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      if (_controller == null) {
        _init();
      } else {
        _controller!.seekTo(Duration.zero);
        _controller!.play();
      }
    } else if (!widget.isActive && old.isActive) {
      _controller?.pause();
    }
  }

  Future<void> _init() async {
    if (_initializing || _controller != null) return;
    _initializing = true;

    final controller = widget.video.source == VideoSource.network
        ? VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
        : VideoPlayerController.file(File(widget.video.videoUrl));

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(_muted ? 0 : 1);
      if (!mounted || !widget.isActive) {
        // Feed moved on before init finished — don't play into the void.
        controller.dispose();
        _initializing = false;
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
      controller.play();
    } catch (_) {
      controller.dispose();
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
        _showPauseIcon = true;
      } else {
        c.play();
        _showPauseIcon = false;
      }
    });
  }

  void _toggleMute() {
    final c = _controller;
    setState(() => _muted = !_muted);
    c?.setVolume(_muted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final video = context.select<VideoProvider, VideoPost?>((p) => p.videoById(widget.video.id)) ?? widget.video;
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            GestureDetector(
              onTap: _togglePlayPause,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),

          if (!ready)
            Container(
              color: AppColors.surfaceSunken,
              alignment: Alignment.center,
              child: _failed
                  ? const Icon(Icons.videocam_off_outlined, color: AppColors.textSecondary, size: 44)
                  : const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
            ),

          // Double-tap-to-like overlay, matching the feed's gesture.
          if (ready)
            Positioned.fill(
              child: DoubleTapLike(
                onLike: () => context.read<VideoProvider>().likeOnly(video.id),
                child: const SizedBox.expand(),
              ),
            ),

          if (ready && _showPauseIcon)
            const Center(
              child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 64),
            ),

          // Bottom gradient + caption/author/category.
          Positioned(
            left: 0,
            right: 72,
            bottom: 70,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 60, 12, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (video.hasCompetitionBadge) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.gold.withOpacity(0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events_rounded, size: 13, color: AppColors.gold),
                          const SizedBox(width: 5),
                          Text(video.competitionBadge!,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.gold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            video.authorName.isNotEmpty ? video.authorName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('${video.authorName} · ${video.authorLevel}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(video.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: Colors.white, height: 1.4)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _pill(video.category),
                      const SizedBox(width: 6),
                      Text(timeAgo(video.createdAt), style: const TextStyle(fontSize: 10.5, color: Colors.white60)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Right action rail.
          Positioned(
            right: 8,
            bottom: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: video.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: video.likedByMe ? AppColors.error : Colors.white,
                  label: _compact(video.likes),
                  onTap: () => context.read<VideoProvider>().toggleLike(video.id),
                ),
                const SizedBox(height: 18),
                _ActionButton(
                  icon: Icons.mode_comment_rounded,
                  label: _compact(video.commentCount),
                  onTap: () => VideoCommentSheet.show(context, video.id),
                ),
                const SizedBox(height: 18),
                _ActionButton(
                  icon: Icons.reply_rounded,
                  label: _compact(video.shares),
                  onTap: () =>
                      ShareSheet.show(context, onShared: () => context.read<VideoProvider>().registerShare(video.id)),
                ),
                const SizedBox(height: 18),
                _ActionButton(
                  icon: video.savedByMe ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: video.savedByMe ? AppColors.primary : Colors.white,
                  label: video.savedByMe ? 'Saved' : 'Save',
                  onTap: () => context.read<VideoProvider>().toggleSave(video.id),
                ),
                const SizedBox(height: 18),
                _ActionButton(
                  icon: Icons.remove_red_eye_outlined,
                  label: _compact(video.views),
                  onTap: null,
                ),
                if (ready) ...[
                  const SizedBox(height: 18),
                  _ActionButton(
                    icon: _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    label: _muted ? 'Muted' : 'Sound',
                    onTap: _toggleMute,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
      );

  String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.color = Colors.white, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.32), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}
