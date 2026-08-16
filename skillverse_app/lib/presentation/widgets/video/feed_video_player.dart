import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/media_source.dart';

/// Feed-embedded video player for [Post]s whose media is a local video
/// file. Lazily initializes the controller only when the user taps to
/// play (feeds can contain many videos at once — we don't want every
/// card decoding a video the moment it scrolls into the tree).
///
/// This is an additive widget for the Video System module. It does not
/// modify any existing screen, provider, or model — it is only wired
/// into [PostCard] in place of the old static placeholder.
class FeedVideoPlayer extends StatefulWidget {
  final String mediaPath;
  final double height;

  const FeedVideoPlayer({
    super.key,
    required this.mediaPath,
    this.height = 200,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitializing = false;
  bool _muted = true;
  bool _failed = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startPlayback() async {
    if (_controller != null) {
      final c = _controller!;
      if (!c.value.isInitialized) return;
      setState(() => c.value.isPlaying ? c.pause() : c.play());
      return;
    }

    if (_isInitializing) return;
    setState(() => _isInitializing = true);

    final controller = isNetworkMediaPath(widget.mediaPath)
        ? VideoPlayerController.networkUrl(Uri.parse(widget.mediaPath))
        : VideoPlayerController.file(File(widget.mediaPath));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(_muted ? 0 : 1);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
      controller.play();
    } catch (_) {
      controller.dispose();
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _failed = true;
      });
    }
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      _muted = !_muted;
      c.setVolume(_muted ? 0 : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Container(
      width: double.infinity,
      height: widget.height,
      color: AppColors.surfaceSunken,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),

          if (_failed)
            const Center(
              child: Icon(Icons.videocam_off_outlined, color: AppColors.textSecondary, size: 40),
            ),

          if (_isInitializing)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
            ),

          if (!_failed && !_isInitializing)
            Center(
              child: GestureDetector(
                onTap: _startPlayback,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                  child: Icon(
                    ready && controller.value.isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),

          if (ready)
            Positioned(
              right: 10,
              bottom: 10,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle),
                  child: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),

          if (ready)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                colors: const VideoProgressColors(
                  playedColor: AppColors.primary,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
