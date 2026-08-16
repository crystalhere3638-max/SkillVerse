import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/post_model.dart';

class MediaPreview extends StatefulWidget {
  final PostMediaType mediaType;
  final String mediaPath;
  final VoidCallback onRemove;

  const MediaPreview({
    super.key,
    required this.mediaType,
    required this.mediaPath,
    required this.onRemove,
  });

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == PostMediaType.video) {
      _controller = VideoPlayerController.file(File(widget.mediaPath))
        ..initialize().then((_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: double.infinity,
              height: 220,
              child: widget.mediaType == PostMediaType.image
                  ? Image.file(File(widget.mediaPath), fit: BoxFit.cover)
                  : _videoPreview(),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
          if (widget.mediaType == PostMediaType.video)
            Positioned.fill(
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    final c = _controller;
                    if (c == null || !c.value.isInitialized) return;
                    setState(() => c.value.isPlaying ? c.pause() : c.play());
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                    child: Icon(
                      (_controller?.value.isPlaying ?? false) ? Icons.pause : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _videoPreview() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return Container(
        color: AppColors.surfaceSunken,
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
    );
  }
}
