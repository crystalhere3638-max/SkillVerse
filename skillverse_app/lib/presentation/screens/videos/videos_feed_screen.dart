import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/video_provider.dart';
import '../../widgets/empty_state.dart';
import 'upload_video_screen.dart';
import 'widgets/video_feed_item.dart';

class VideosFeedScreen extends StatefulWidget {
  const VideosFeedScreen({super.key});

  @override
  State<VideosFeedScreen> createState() => _VideosFeedScreenState();
}

class _VideosFeedScreenState extends State<VideosFeedScreen> {
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VideoProvider>();
      provider.init().then((_) {
        if (mounted && provider.videos.isNotEmpty) {
          // Register the view for whichever video lands on page 0.
          provider.setActiveIndex(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openUpload() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UploadVideoScreen(), fullscreenDialog: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Consumer<VideoProvider>(
        builder: (context, provider, _) {
          if (provider.isInitialLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.error != null) {
            return Center(
              child: EmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Something went wrong',
                message: provider.error!,
                actionLabel: 'Retry',
                onAction: provider.retry,
              ),
            );
          }

          final videos = provider.videos;
          if (videos.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.videocam_off_outlined,
                title: 'No videos yet',
                message: 'Be the first to share a video on SkillVerse.',
                actionLabel: 'Upload a video',
                onAction: _openUpload,
              ),
            );
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: videos.length,
                onPageChanged: provider.setActiveIndex,
                itemBuilder: (context, index) {
                  return VideoFeedItem(
                    key: ValueKey(videos[index].id),
                    video: videos[index],
                    isActive: index == provider.activeIndex,
                  );
                },
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Videos',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
                      GestureDetector(
                        onTap: _openUpload,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), shape: BoxShape.circle),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
