import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/video_post_model.dart';
import '../../../providers/post_provider.dart';
import '../../../providers/video_provider.dart';
import '../../widgets/post_card.dart';

class ProfileTabs extends StatefulWidget {
  final String uid;
  const ProfileTabs({super.key, required this.uid});

  @override
  State<ProfileTabs> createState() => _ProfileTabsState();
}

class _ProfileTabsState extends State<ProfileTabs> {
  int _tab = 0;

  Widget _tabButton(String label, int index) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? Colors.greenAccent : AppColors.divider,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.white54)),
      ),
    );
  }

  Widget _reelCard(VideoPost v) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.caption.isEmpty ? '(no caption)' : v.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '${v.category}  •  ${v.views} views  •  ${v.likes} likes',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _postsTab(PostProvider posts) {
    final list = posts.postsByAuthorId(widget.uid);
    if (list.isEmpty) return [_empty('No posts yet')];
    return [for (final p in list) PostCard(post: p)];
  }

  List<Widget> _reelsTab(VideoProvider videos) {
    final list = videos.videosByAuthorId(widget.uid);
    if (list.isEmpty) return [_empty('No reels yet')];
    return [for (final v in list) _reelCard(v)];
  }

  List<Widget> _savedTab(PostProvider posts, VideoProvider videos) {
    final savedPosts = posts.savedPosts;
    final savedVideos = videos.savedVideos;
    if (savedPosts.isEmpty && savedVideos.isEmpty) {
      return [_empty('Nothing saved yet')];
    }
    return [
      for (final p in savedPosts) PostCard(post: p),
      for (final v in savedVideos) _reelCard(v),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<PostProvider>();
    final videos = context.watch<VideoProvider>();

    List<Widget> content;
    if (_tab == 0) {
      content = _postsTab(posts);
    } else if (_tab == 1) {
      content = _reelsTab(videos);
    } else {
      content = _savedTab(posts, videos);
    }

    return Column(
      children: [
        Row(
          children: [
            _tabButton('Posts', 0),
            _tabButton('Reels', 1),
            _tabButton('Saved', 2),
          ],
        ),
        ...content,
      ],
    );
  }
}
