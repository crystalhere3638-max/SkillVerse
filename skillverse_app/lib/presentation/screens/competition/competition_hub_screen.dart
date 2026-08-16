import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/competition_model.dart';
import '../../../providers/competition_provider.dart';
import '../../widgets/competition_card.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../missions/daily_missions_screen.dart';
import 'competition_details_screen.dart';

class CompetitionHubScreen extends StatelessWidget {
  const CompetitionHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompetitionProvider>();
    final featured = provider.featured;
    final daily = provider.byType(CompetitionType.daily);
    final weekly = provider.byType(CompetitionType.weekly);
    final monthly = provider.byType(CompetitionType.monthly);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Competitions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2)),
            Row(
              children: [
                _QuickIconButton(
                  icon: Icons.checklist_rounded,
                  tooltip: 'Daily Missions',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DailyMissionsScreen())),
                ),
                const SizedBox(width: 8),
                _QuickIconButton(
                  icon: Icons.leaderboard_rounded,
                  tooltip: 'Leaderboard',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (featured != null) ...[
          const _SectionHeader(title: 'Featured Competition', icon: Icons.star_rounded, color: AppColors.gold),
          const SizedBox(height: 12),
          CompetitionCard(
            competition: featured,
            large: true,
            onTap: () => _openDetails(context, featured.id),
            onJoin: () => context.read<CompetitionProvider>().join(featured.id),
          ),
          const SizedBox(height: 28),
        ],
        _SectionHeader(title: 'Daily Competitions', icon: Icons.today_rounded, color: AppColors.primary),
        const SizedBox(height: 12),
        _HorizontalList(competitions: daily, onOpen: (id) => _openDetails(context, id)),
        const SizedBox(height: 28),
        _SectionHeader(title: 'Weekly Competitions', icon: Icons.view_week_rounded, color: AppColors.blue),
        const SizedBox(height: 12),
        _HorizontalList(competitions: weekly, onOpen: (id) => _openDetails(context, id)),
        const SizedBox(height: 28),
        _SectionHeader(title: 'Monthly Competitions', icon: Icons.calendar_month_rounded, color: AppColors.orange),
        const SizedBox(height: 12),
        _HorizontalList(competitions: monthly, onOpen: (id) => _openDetails(context, id)),
      ],
    );
  }

  void _openDetails(BuildContext context, String id) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CompetitionDetailsScreen(competitionId: id)));
  }
}

class _HorizontalList extends StatelessWidget {
  final List<CompetitionModel> competitions;
  final ValueChanged<String> onOpen;
  const _HorizontalList({required this.competitions, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (competitions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('Nothing here yet — check back soon.', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
      );
    }
    return SizedBox(
      height: 232,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: competitions.length,
        itemBuilder: (_, i) {
          final c = competitions[i];
          return CompetitionCard(
            competition: c,
            onTap: () => onOpen(c.id),
            onJoin: () => context.read<CompetitionProvider>().join(c.id),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 7),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }
}

class _QuickIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _QuickIconButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.divider)),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
