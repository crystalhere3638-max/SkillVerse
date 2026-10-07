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
    bool _showSearch = false;

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

                        final videos = provider.filteredVideos;
              if (provider.videos.isEmpty) {
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
                                      Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 64,
              child: GestureDetector(
                onTap: () {
                  final p = context.read<VideoProvider>();
                  if (_showSearch) {
                    p.setCategoryFilter('All');
                    p.setSearchQuery('');
                  }
                  setState(() => _showSearch = !_showSearch);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), shape: BoxShape.circle),
                  child: Icon(_showSearch ? Icons.close : Icons.search, color: Colors.white, size: 22),
                ),
              ),
            ),
            if (_showSearch) Positioned(
              top: MediaQuery.of(context).padding.top + 54,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      onChanged: provider.setSearchQuery,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search reels or categories',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.45),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 46,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      children: [
                        for (final c in ['All', ...provider.videos.map((v) => v.category).toSet()])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(c),
                              selected: provider.categoryFilter == c,
                              onSelected: (_) => provider.setCategoryFilter(c),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ],
          );
        },
      ),
    );
  }
}
