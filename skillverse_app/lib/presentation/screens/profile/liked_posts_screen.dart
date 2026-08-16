import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/post_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/post_card.dart';

class LikedPostsScreen extends StatelessWidget {
  const LikedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<PostProvider>().likedPosts;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text('Liked Posts', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: posts.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'No liked posts',
              message: 'Posts you like will show up here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => PostCard(post: posts[i]),
            ),
    );
  }
}
