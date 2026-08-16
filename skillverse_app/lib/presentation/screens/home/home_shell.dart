import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/level_up_celebration.dart';
import '../competition/competition_hub_screen.dart';
import '../create_post/create_post_screen.dart';
import '../videos/videos_feed_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Shows the Skill Journey level-up popup the moment UserProvider
  // detects a level increase, then marks it consumed so it never
  // replays (e.g. on rebuild or navigating tabs).
  void _maybeShowLevelUp(UserProvider userProvider) {
    final newLevel = userProvider.pendingLevelUp;
    if (newLevel == null) return;
    userProvider.consumeLevelUp();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showLevelUpCelebration(context, newLevel: newLevel, xpEarned: 0, coinsEarned: 0);
    });
  }

  static const _tabs = ['home', 'compete', 'create', 'videos', 'community', 'profile'];

  /// The Create tab opens the composer as a full-screen route (rather
  /// than swapping tab content) so publishing can pop straight back to
  /// whichever tab the user was already on — this does not change the
  /// bottom nav itself, only what tapping the center button does.
  Future<void> _openCreatePost() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen(), fullscreenDialog: true),
    );
  }

  void _onTabTap(int i) {
    if (_tabs[i] == 'create') {
      _openCreatePost();
      return;
    }
    setState(() => _index = i);
  }

  Widget _body() {
    switch (_tabs[_index]) {
      case 'home':
        return const HomeScreen();
      case 'compete':
        return const CompetitionHubScreen();
      case 'create':
        // Unreachable via tap (handled by _openCreatePost), kept as a
        // safe fallback so _index can never render a blank screen.
        return const _PlaceholderTab(
          title: 'Create',
          icon: Icons.add_circle_outline,
          message: 'Post lessons and showcase your work once Create is live.',
        );
      case 'videos':
        return const VideosFeedScreen();
      case 'community':
        return const _PlaceholderTab(
          title: 'Community',
          icon: Icons.chat_bubble_outline,
          message: 'Connect with other creators once the community goes live.',
        );
      case 'profile':
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    _maybeShowLevelUp(context.watch<UserProvider>());
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      body: SafeArea(bottom: false, child: _body()),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onTap: _onTabTap,
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;
  const _PlaceholderTab({required this.title, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2)),
        ),
        Expanded(child: EmptyState(icon: icon, title: 'Nothing here yet', message: message)),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.emoji_events_rounded, 'Compete'),
    (Icons.add_rounded, 'Create'),
    (Icons.play_circle_fill_rounded, 'Videos'),
    (Icons.groups_rounded, 'Community'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withOpacity(0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 10))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final (icon, label) = _items[i];
            final active = i == index;
            if (i == 2) {
              return GestureDetector(
                onTap: () => onTap(i),
                child: Container(
                  width: 52,
                  height: 52,
                  margin: const EdgeInsets.only(top: -22),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 18)],
                  ),
                  child: Icon(icon, color: Colors.black, size: 26),
                ),
              );
            }
            return GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20, color: active ? AppColors.primary : AppColors.textMuted),
                    const SizedBox(height: 3),
                    Text(label,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                          color: active ? AppColors.primary : AppColors.textMuted,
                        )),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
