import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/competition_model.dart';
import '../../../providers/competition_provider.dart';
import '../../../providers/leaderboard_provider.dart';
import '../../widgets/countdown_timer.dart';
import '../leaderboard/leaderboard_screen.dart';

class CompetitionDetailsScreen extends StatefulWidget {
  final String competitionId;
  const CompetitionDetailsScreen({super.key, required this.competitionId});

  @override
  State<CompetitionDetailsScreen> createState() => _CompetitionDetailsScreenState();
}

class _CompetitionDetailsScreenState extends State<CompetitionDetailsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _joinController;
  bool _showJoinBurst = false;

  @override
  void initState() {
    super.initState();
    _joinController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _joinController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin(CompetitionModel c) async {
    context.read<CompetitionProvider>().join(c.id);
    setState(() => _showJoinBurst = true);
    _joinController.forward(from: 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You're in! Good luck in ${c.title} 🎉")),
    );
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _showJoinBurst = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CompetitionProvider>().byId(widget.competitionId);
    if (c == null) {
      return const Scaffold(backgroundColor: AppColors.bg, body: Center(child: Text('Competition not found', style: TextStyle(color: Colors.white))));
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.bg,
                pinned: true,
                expandedHeight: 190,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(gradient: LinearGradient(colors: c.bannerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight)),
                    child: Stack(
                      children: [
                        Positioned(right: -20, bottom: -20, child: Icon(c.bannerIcon, size: 160, color: Colors.black.withOpacity(0.15))),
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 18,
                          child: Text(c.title,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black.withOpacity(0.85))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _InfoChip(icon: Icons.category_outlined, label: c.category),
                          const SizedBox(width: 8),
                          _InfoChip(icon: Icons.speed_rounded, label: c.difficulty.label, color: c.difficulty.color),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: _StatTile(icon: Icons.bolt_rounded, label: 'XP Reward', value: '${c.xpReward}', color: AppColors.primary)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatTile(icon: Icons.monetization_on_rounded, label: 'Coin Reward', value: '${c.coinReward}', color: AppColors.gold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _StatTile(icon: Icons.groups_rounded, label: 'Participants', value: '${c.participants}', color: AppColors.blue)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Time Left', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  CountdownTimer(target: c.endsAt),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      const Text('Description', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text(c.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                      const SizedBox(height: 22),
                      const Text('Rules', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 8),
                      ...c.rules.map((r) => _BulletLine(text: r, icon: Icons.check_circle_outline_rounded, color: AppColors.primary)),
                      const SizedBox(height: 22),
                      const Text('Requirements', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 8),
                      ...c.requirements.map((r) => _BulletLine(text: r, icon: Icons.info_outline_rounded, color: AppColors.blue)),
                      const SizedBox(height: 22),
                      const Text('Previous Winners', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 10),
                      ...c.previousWinners.map((w) => _WinnerTile(winner: w)),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Leaderboard Preview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                            child: const Text('View all', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const _LeaderboardPreview(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showJoinBurst)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _joinController,
                builder: (_, __) {
                  final v = _joinController.value;
                  return Opacity(
                    opacity: (1 - v).clamp(0, 1),
                    child: Center(
                      child: Transform.scale(
                        scale: 0.6 + v * 1.6,
                        child: Icon(Icons.emoji_events_rounded, size: 90, color: AppColors.gold.withOpacity(0.9)),
                      ),
                    ),
                  );
                },
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: c.joined || c.status == CompetitionStatus.ended ? null : () => _handleJoin(c),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.joined ? AppColors.surfaceElevated : AppColors.primary,
                  foregroundColor: c.joined ? AppColors.primary : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  c.status == CompetitionStatus.ended ? 'Competition Ended' : (c.joined ? 'You\'re Joined ✓' : 'Join Competition'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardPreview extends StatelessWidget {
  const _LeaderboardPreview();

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<LeaderboardProvider>().entries.take(3).toList();
    return Column(
      children: entries
          .map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                child: Row(
                  children: [
                    Text('#${e.rank}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.gold)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(e.username, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
                    Text('${e.score} pts', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _WinnerTile extends StatelessWidget {
  final CompetitionWinner winner;
  const _WinnerTile({required this.winner});

  @override
  Widget build(BuildContext context) {
    final medalColor = winner.rank == 1 ? AppColors.gold : (winner.rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: medalColor, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(winner.username, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
          Text(winner.reward, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _BulletLine({required this.text, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4))),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(0.35))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))]),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }
}
