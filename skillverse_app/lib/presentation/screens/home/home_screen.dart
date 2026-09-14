import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../core/utils/skill_level_engine.dart';
import '../../../data/models/app_user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/post_provider.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/category_filter_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/feed_tab_bar.dart';
import '../../widgets/level_title_badge.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/post_card.dart';
import '../../widgets/post_card_skeleton.dart';
import '../../widgets/pressable_scale.dart';
import '../../../providers/competition_provider.dart';
import '../../../providers/leaderboard_provider.dart';
import '../../../providers/mission_provider.dart';
import '../../../providers/notification_provider.dart';
import '../competition/competition_details_screen.dart';
import '../journey/skill_journey_screen.dart';
import '../missions/daily_missions_screen.dart';
import '../notifications/notifications_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _requestedLoad = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Infinite scroll: request the next page once the user is close to
  // the bottom, rather than waiting for them to hit it exactly — feels
  // faster and avoids a visible pop-in of the loader.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 400;
    if (_scrollController.position.pixels >= threshold) {
      context.read<PostProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
    final auth = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final postProvider = context.watch<PostProvider>();
    final profile = userProvider.profile ?? auth.user;
    final username = profile?.username ?? 'Learner';

    if (!_requestedLoad) {
      _requestedLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PostProvider>().init());
    }

      return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: () => context.read<PostProvider>().refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        // Ensures pull-to-refresh works even when content is short
        // enough not to naturally overscroll.
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
      const SliverToBoxAdapter(child: SizedBox(height: 150, child: ColoredBox(color: Colors.orange, child: Center(child: Text('TEST', style: TextStyle(fontSize: 30, color: Colors.black)))))),
            
          const SliverToBoxAdapter(child: OfflineBanner()),
          SliverToBoxAdapter(
            child: _Header(username: username, profile: profile),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
              child: FeedTabBar(
                selected: postProvider.feedType,
                onChanged: (type) => context.read<PostProvider>().setFeedType(type),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: CategoryFilterBar(
                selected: postProvider.categoryFilter,
                onChanged: (cat) => context.read<PostProvider>().setCategoryFilter(cat),
              ),
            ),
          ),
          _buildFeedSliver(postProvider),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
        );
      
  } catch (e, st) {
      return Center(child: Text('HOME ERROR: $e', style: const TextStyle(color: Colors.red, fontSize: 12)));
    }
  }

  Widget _buildFeedSliver(PostProvider postProvider) {
    if (postProvider.isInitialLoading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const PostCardSkeleton(),
        ),
      );
    }

    if (postProvider.error != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: ErrorStateView(onRetry: () => context.read<PostProvider>().retry()),
        ),
      );
    }

    if (postProvider.feedItems.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: EmptyState(
            icon: Icons.dynamic_feed_outlined,
            title: 'No posts here yet',
            message: 'Try a different category or tap the + button to share something.',
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.separated(
        itemCount: postProvider.feedItems.length + 1, // +1 for the footer slot
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == postProvider.feedItems.length) {
            return _FeedFooter(
              isLoadingMore: postProvider.isLoadingMore,
              hasMore: postProvider.hasMore,
            );
          }
          final post = postProvider.feedItems[index];
          // RepaintBoundary + a stable key keep scrolling smooth: each
          // card repaints independently instead of the whole list.
          return RepaintBoundary(
            key: ValueKey(post.id),
            child: PostCard(post: post),
          );
        },
      ),
    );
  }
}

class _FeedFooter extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMore;
  const _FeedFooter({required this.isLoadingMore, required this.hasMore});

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
          ),
        ),
      );
    }
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text("You're all caught up", style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _Header extends StatelessWidget {
  final String username;
  final AppUser? profile;
  const _Header({required this.username, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome back 👋', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SkillJourneyScreen(totalXp: SkillLevelInfo.fromLevel(profile?.level ?? 1).totalXp),
                        ),
                      ),
                      child: LevelTitleBadge.fromLevel(profile?.level ?? 1, compact: true),
                    ),
                  ],
                ),
              ),
              _HeaderIconButton(
                icon: Icons.search_rounded,
                tooltip: 'Search',
                onTap: () => Navigator.of(context).push(SlideFadeRoute(builder: (_) => const SearchScreen())),
              ),
              const SizedBox(width: 8),
              Consumer<NotificationProvider>(
                builder: (_, notif, __) => _HeaderIconButton(
                  icon: Icons.notifications_none_rounded,
                  tooltip: 'Notifications',
                  unreadCount: notif.unreadCount,
                  onTap: () => Navigator.of(context).push(SlideFadeRoute(builder: (_) => const NotificationsScreen())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(icon: Icons.bolt_rounded, value: '${profile?.xp ?? 0}', label: 'XP', color: AppColors.primary),
              const SizedBox(width: 8),
              _StatChip(icon: Icons.monetization_on_outlined, value: '${profile?.coins ?? 0}', label: 'Coins', color: AppColors.gold),
              const SizedBox(width: 8),
              _StatChip(icon: Icons.local_fire_department_outlined, value: '${profile?.streak ?? 0}', label: 'Streak', color: AppColors.orange),
              const SizedBox(width: 8),
              Consumer<LeaderboardProvider>(
                builder: (_, lb, __) {
                  final rank = lb.entries.firstWhere((e) => e.isCurrentUser, orElse: () => lb.entries.last).rank;
                  return _StatChip(icon: Icons.leaderboard_rounded, value: '#$rank', label: 'Rank', color: AppColors.blue);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _XpProgressBar(level: profile?.level ?? 1),
          const SizedBox(height: 12),
          const _TodayMissionAndCompeteRow(),
          if (profile?.mainCategory != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category_outlined, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${profile!.mainCategory} · ${profile!.goal}',
                      style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Home dashboard row: a quick glance at today's mission progress plus a
/// one-tap shortcut into the featured competition — keeps Home as the
/// jumping-off point without duplicating the full Competition Hub UI.
class _TodayMissionAndCompeteRow extends StatelessWidget {
  const _TodayMissionAndCompeteRow();

  @override
  Widget build(BuildContext context) {
    final missions = context.watch<MissionProvider>();
    final featured = context.watch<CompetitionProvider>().featured;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: PressableScale(
            onTap: () => Navigator.of(context).push(SlideFadeRoute(builder: (_) => const DailyMissionsScreen())),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.checklist_rounded, size: 15, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text("Today's Missions", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: missions.missions.isEmpty ? 0 : missions.completedCount / missions.missions.length,
                      minHeight: 6,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${missions.completedCount}/${missions.missions.length} done', style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: missions.missions
                        .map((m) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                m.claimed ? Icons.check_circle_rounded : (m.isCompleted ? Icons.check_circle_outline_rounded : Icons.circle_outlined),
                                size: 14,
                                color: m.isCompleted ? AppColors.primary : AppColors.textMuted,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PressableScale(
            onTap: featured == null
                ? null
                : () => Navigator.of(context).push(SlideFadeRoute(builder: (_) => CompetitionDetailsScreen(competitionId: featured.id))),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: featured?.bannerGradient ?? [AppColors.gold, AppColors.orange]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.emoji_events_rounded, size: 15, color: Colors.black87),
                      SizedBox(width: 6),
                      Text('Quick Join', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    featured?.title ?? 'No featured event',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.black),
                  ),
                  const Spacer(),
                  if (featured != null)
                    Text(featured.joined ? 'Joined ✓' : 'Tap to join →', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.black87)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact XP progress bar for the Home dashboard — shows progress
/// toward the next level right under the stat chips.
class _XpProgressBar extends StatelessWidget {
  final int level;
  const _XpProgressBar({required this.level});

  @override
  Widget build(BuildContext context) {
    final info = SkillLevelInfo.fromLevel(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level ${info.level} · ${info.title}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('${info.xpIntoLevel}/${info.xpForThisLevel} XP', style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: info.progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular icon button used in the Home header (search, notifications).
/// Kept at a 44x44 minimum footprint for comfortable touch targets, with
/// an optional unread-count badge in the top-right corner.
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int unreadCount;
  const _HeaderIconButton({required this.icon, required this.tooltip, required this.onTap, this.unreadCount = 0});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: unreadCount > 0 ? '$tooltip, $unreadCount unread' : tooltip,
      child: Tooltip(
        message: tooltip,
        child: PressableScale(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.divider)),
                  child: Icon(icon, color: AppColors.textSecondary, size: 19),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle, border: Border.all(color: AppColors.bg, width: 1.5)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
