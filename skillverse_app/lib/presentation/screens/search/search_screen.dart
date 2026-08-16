import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/post_categories.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/competition_model.dart';
import '../../../data/models/post_model.dart';
import '../../../providers/competition_provider.dart';
import '../../../providers/post_provider.dart';
import '../../widgets/empty_state.dart';
import '../competition/competition_details_screen.dart';

/// Single lightweight search surface across users, posts, competitions
/// and categories — no separate index/backend, just filters over data
/// already held in memory by existing providers.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  static const _recentSearches = ['Flutter', 'ArjunCodes', 'Graphic Design'];
  static const _trendingSearches = ['AI Prompt Masters', 'Programming', 'Weekly Build-Off'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final posts = context.watch<PostProvider>();
    final competitions = context.watch<CompetitionProvider>();

    final matchedUsers = q.isEmpty
        ? <String>[]
        : {for (final p in posts.feedItems) p.authorName}.where((u) => u.toLowerCase().contains(q)).toList();
    final matchedPosts = q.isEmpty
        ? <Post>[]
        : posts.feedItems.where((p) => p.caption.toLowerCase().contains(q) || p.authorName.toLowerCase().contains(q)).toList();
    final matchedCompetitions = q.isEmpty
        ? <CompetitionModel>[]
        : competitions.competitions.where((c) => c.title.toLowerCase().contains(q) || c.category.toLowerCase().contains(q)).toList();
    final matchedCategories = q.isEmpty ? <String>[] : postCategories.map((c) => c.name).where((c) => c.toLowerCase().contains(q)).toList();

    final hasResults = matchedUsers.isNotEmpty || matchedPosts.isNotEmpty || matchedCompetitions.isNotEmpty || matchedCategories.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.divider)),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Search users, posts, competitions...',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (_controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() {
                    _controller.clear();
                    _query = '';
                  }),
                  child: const Icon(Icons.close_rounded, size: 17, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
      ),
      body: q.isEmpty
          ? _SuggestionsView(
              recent: _recentSearches,
              trending: _trendingSearches,
              onTapSuggestion: (s) => setState(() {
                _controller.text = s;
                _query = s;
              }),
            )
          : !hasResults
              ? const EmptyState(icon: Icons.search_off_rounded, title: 'No results found', message: 'Try a different keyword or check your spelling.')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    if (matchedUsers.isNotEmpty) ...[
                      const _ResultHeader(title: 'Users'),
                      ...matchedUsers.map((u) => _UserResultTile(username: u)),
                    ],
                    if (matchedCategories.isNotEmpty) ...[
                      const _ResultHeader(title: 'Categories'),
                      Wrap(spacing: 8, runSpacing: 8, children: matchedCategories.map((c) => _CategoryChip(name: c)).toList()),
                      const SizedBox(height: 8),
                    ],
                    if (matchedCompetitions.isNotEmpty) ...[
                      const _ResultHeader(title: 'Competitions'),
                      ...matchedCompetitions.map((c) => _CompetitionResultTile(competition: c)),
                    ],
                    if (matchedPosts.isNotEmpty) ...[
                      const _ResultHeader(title: 'Posts'),
                      ...matchedPosts.map((p) => _PostResultTile(post: p)),
                    ],
                  ],
                ),
    );
  }
}

class _SuggestionsView extends StatelessWidget {
  final List<String> recent;
  final List<String> trending;
  final ValueChanged<String> onTapSuggestion;
  const _SuggestionsView({required this.recent, required this.trending, required this.onTapSuggestion});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        const _ResultHeader(title: 'Recent Searches'),
        Wrap(spacing: 8, runSpacing: 8, children: recent.map((s) => _SuggestionChip(label: s, icon: Icons.history_rounded, onTap: () => onTapSuggestion(s))).toList()),
        const SizedBox(height: 22),
        const _ResultHeader(title: 'Trending Searches'),
        Wrap(spacing: 8, runSpacing: 8, children: trending.map((s) => _SuggestionChip(label: s, icon: Icons.trending_up_rounded, onTap: () => onTapSuggestion(s))).toList()),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.divider)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final String title;
  const _ResultHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String name;
  const _CategoryChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.blue.withOpacity(0.35))),
      child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue)),
    );
  }
}

class _UserResultTile extends StatelessWidget {
  final String username;
  const _UserResultTile({required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withOpacity(0.18),
            child: Text(username.isNotEmpty ? username[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Text(username, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

class _CompetitionResultTile extends StatelessWidget {
  final CompetitionModel competition;
  const _CompetitionResultTile({required this.competition});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CompetitionDetailsScreen(competitionId: competition.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
        child: Row(
          children: [
            Icon(competition.bannerIcon, size: 18, color: competition.bannerGradient.first),
            const SizedBox(width: 12),
            Expanded(child: Text(competition.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white))),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _PostResultTile extends StatelessWidget {
  final Post post;
  const _PostResultTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post.authorName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 3),
          Text(post.caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: Colors.white)),
        ],
      ),
    );
  }
}
