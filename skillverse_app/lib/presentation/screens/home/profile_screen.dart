import '../../../data/models/activity_model.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_ago.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/post_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../core/utils/skill_level_engine.dart';
import '../../../providers/badge_provider.dart';
import '../../../providers/leaderboard_provider.dart';
import '../../widgets/level_title_badge.dart';
import '../badges/badge_gallery_screen.dart';
import '../journey/skill_journey_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../profile/liked_posts_screen.dart';
import '../profile/recent_activity_screen.dart';
import '../profile/saved_posts_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _initialAvatar(String username) => Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.black),
        ),
      );

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null || !context.mounted) return;
    await context.read<UserProvider>().updateProfilePhoto(File(picked.path));
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Sign out?', style: TextStyle(color: Colors.white)),
        content: const Text('You can log back in anytime.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final postProvider = context.watch<PostProvider>();
    final profile = userProvider.profile ?? auth.user;
    final username = profile?.username ?? 'Learner';
    final recentActivity = postProvider.activityLog.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2)),
              Semantics(
                button: true,
                label: 'Settings',
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: userProvider.isUploadingPhoto ? null : () => _pickAndUploadPhoto(context),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                        child: Container(
                          decoration: const BoxDecoration(color: AppColors.bg, shape: BoxShape.circle),
                          child: Center(
                            child: Container(
                              width: 84,
                              height: 84,
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                              child: (profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty)
                                  ? Image.network(
                                      profile.photoUrl!,
                                      fit: BoxFit.cover,
                                      width: 84,
                                      height: 84,
                                      errorBuilder: (_, __, ___) => _initialAvatar(username),
                                      loadingBuilder: (context, child, progress) =>
                                          progress == null ? child : _initialAvatar(username),
                                    )
                                  : _initialAvatar(username),
                            ),
                          ),
                        ),
                      ),
                      if (userProvider.isUploadingPhoto)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                            child: Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  value: userProvider.photoUploadProgress > 0 ? userProvider.photoUploadProgress : null,
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.bg, width: 2.5),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.black),
                          ),
                        ),
                    ],
                  ),
                ),
                if (userProvider.photoUploadError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: () => _pickAndUploadPhoto(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 13, color: AppColors.error),
                          const SizedBox(width: 4),
                          const Text('Upload failed — tap to retry',
                              style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Text(username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 8),
                LevelTitleBadge.fromLevel(profile?.level ?? 1),
                const SizedBox(height: 2),
                Text(profile?.email ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                if (profile?.mainCategory != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: Text('${profile!.mainCategory} · ${profile.goal}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SkillJourneyCard(level: profile?.level ?? 1),
          const SizedBox(height: 22),
          Row(
            children: [
              _StatBox(label: 'Level', value: '${profile?.level ?? 1}', icon: Icons.military_tech_outlined),
              const SizedBox(width: 10),
              _StatBox(label: 'XP', value: '${profile?.xp ?? 0}', icon: Icons.bolt_rounded),
              const SizedBox(width: 10),
              _StatBox(label: 'Coins', value: '${profile?.coins ?? 0}', icon: Icons.monetization_on_outlined),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatBox(label: 'Rating', value: '${profile?.skillRating.toStringAsFixed(1) ?? "0.0"}', icon: Icons.star_border_rounded),
              const SizedBox(width: 10),
              _StatBox(label: 'Followers', value: '${profile?.followers ?? 0}', icon: Icons.groups_outlined),
              const SizedBox(width: 10),
              _StatBox(label: 'Following', value: '${profile?.following ?? 0}', icon: Icons.person_outline),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: _NavTile(
                  icon: Icons.bookmark_rounded,
                  label: 'Saved Posts',
                  count: postProvider.savedPosts.length,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavedPostsScreen())),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NavTile(
                  icon: Icons.favorite_rounded,
                  label: 'Liked Posts',
                  count: postProvider.likedPosts.length,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LikedPostsScreen())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _NavTile(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Badges',
                  count: context.watch<BadgeProvider>().unlocked.length,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BadgeGalleryScreen())),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Builder(builder: (context) {
                  final entries = context.watch<LeaderboardProvider>().entries;
                  final rank = entries.firstWhere((e) => e.isCurrentUser, orElse: () => entries.last).rank;
                  return _NavTile(
                    icon: Icons.leaderboard_rounded,
                    label: 'Leaderboard',
                    count: rank,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 26),
          const Text('Activity Summary', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.1)),
          const SizedBox(height: 13),
          Row(
            children: [
              _StatBox(
                label: 'Posts',
                value: '${postProvider.postsByAuthor(username).length}',
                icon: Icons.upload_rounded,
              ),
              const SizedBox(width: 10),
              _StatBox(label: 'Likes Given', value: '${postProvider.likedPosts.length}', icon: Icons.favorite_rounded),
              const SizedBox(width: 10),
              _StatBox(
                label: 'Comments',
                value: '${postProvider.commentsMadeBy(username)}',
                icon: Icons.chat_bubble_rounded,
              ),
            ],
          ),

          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Activity', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.1)),
              if (recentActivity.isNotEmpty)
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecentActivityScreen())),
                  child: const Text('View all ›', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentActivity.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Text('No activity yet — like, comment, or save a post to see it here.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            )
          else
            Column(
              children: [
                for (final entry in recentActivity)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                            child: Icon(entry.type.icon, size: 14, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('${entry.type.verb()} · ${timeAgo(entry.timestamp)}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: auth.isLoading ? null : () => _confirmSignOut(context),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 12),
                  Text(
                    auth.isLoading ? 'Signing out…' : 'Sign Out',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillJourneyCard extends StatelessWidget {
  final int level;
  const _SkillJourneyCard({required this.level});

  @override
  Widget build(BuildContext context) {
    final info = SkillLevelInfo.fromLevel(level);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SkillJourneyScreen(totalXp: info.totalXp)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.gold.withOpacity(0.14), AppColors.surfaceElevated]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gold.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.gold, AppColors.orange]),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(info.emoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Skill Journey', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(
                    info.nextTier != null
                        ? '${info.levelsUntilNextTier} level${info.levelsUntilNextTier == 1 ? '' : 's'} to ${info.nextTier!.title}'
                        : 'You reached the top title',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatBox({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.label, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('$count', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
