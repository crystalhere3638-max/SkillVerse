import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../data/models/competition_model.dart';

/// Drives the Competition Hub + Competition Details screens.
/// Uses local mock data for now; swap [_seedCompetitions] for a
/// Firestore-backed repository later without touching any UI.
class CompetitionProvider extends ChangeNotifier {
  List<CompetitionModel> _competitions = [];
  List<CompetitionModel> get competitions => _competitions;

  CompetitionProvider() {
    _competitions = _seedCompetitions();
  }

  CompetitionModel? byId(String id) {
    try {
      return _competitions.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CompetitionModel> byType(CompetitionType type) =>
      _competitions.where((c) => c.type == type).toList();

  CompetitionModel? get featured => _competitions.where((c) => c.type == CompetitionType.featured).isNotEmpty
      ? _competitions.firstWhere((c) => c.type == CompetitionType.featured)
      : null;

  void join(String id) {
    final index = _competitions.indexWhere((c) => c.id == id);
    if (index == -1 || _competitions[index].joined) return;
    _competitions[index] = _competitions[index].copyWith(
      joined: true,
      participants: _competitions[index].participants + 1,
    );
    notifyListeners();
  }

  List<CompetitionModel> _seedCompetitions() {
    final now = DateTime.now();
    return [
      CompetitionModel(
        id: 'feat_01',
        title: 'SkillVerse Grand Challenge',
        category: 'Programming',
        bannerIcon: Icons.emoji_events_rounded,
        bannerGradient: const [AppColors.gold, AppColors.orange],
        difficulty: CompetitionDifficulty.advanced,
        type: CompetitionType.featured,
        xpReward: 800,
        coinReward: 500,
        participants: 2140,
        endsAt: now.add(const Duration(days: 4, hours: 6)),
        status: CompetitionStatus.live,
        description:
            'The flagship SkillVerse event — solve a full build challenge, submit your project, and get scored by the community and top mentors.',
        rules: [
          'One submission per user',
          'Original work only — no templates',
          'Submit before the countdown ends',
          'Judged on creativity, execution, and polish',
        ],
        requirements: ['Level 5+', 'Verified profile', 'Category: Programming or Design'],
        previousWinners: const [
          CompetitionWinner(username: 'ArjunCodes', rank: 1, reward: '₹5,000 + 1000 XP'),
          CompetitionWinner(username: 'PixelPriya', rank: 2, reward: '₹2,500 + 600 XP'),
          CompetitionWinner(username: 'DevRohanX', rank: 3, reward: '₹1,000 + 300 XP'),
        ],
      ),
      CompetitionModel(
        id: 'daily_01',
        title: 'Speed Code Sprint',
        category: 'Programming',
        bannerIcon: Icons.bolt_rounded,
        bannerGradient: const [AppColors.primary, AppColors.primaryDark],
        difficulty: CompetitionDifficulty.beginner,
        type: CompetitionType.daily,
        xpReward: 60,
        coinReward: 30,
        participants: 412,
        endsAt: now.add(const Duration(hours: 9)),
        status: CompetitionStatus.live,
        description: 'A quick daily coding puzzle. Solve it fast and climb today\'s leaderboard.',
        rules: ['Resets every 24 hours', 'Top 10 get bonus coins', 'One attempt per day'],
        requirements: ['Any level'],
        previousWinners: const [
          CompetitionWinner(username: 'ByteQueen', rank: 1, reward: '80 XP + 40 Coins'),
        ],
      ),
      CompetitionModel(
        id: 'daily_02',
        title: 'Design Doodle of the Day',
        category: 'Graphic Design',
        bannerIcon: Icons.brush_rounded,
        bannerGradient: const [AppColors.blue, Color(0xFF7E57C2)],
        difficulty: CompetitionDifficulty.beginner,
        type: CompetitionType.daily,
        xpReward: 60,
        coinReward: 30,
        participants: 268,
        endsAt: now.add(const Duration(hours: 9)),
        status: CompetitionStatus.live,
        description: 'Create a quick themed doodle and share it — community votes decide the winner.',
        rules: ['Resets every 24 hours', 'Original art only', 'One entry per day'],
        requirements: ['Any level'],
        previousWinners: const [
          CompetitionWinner(username: 'InkedIsha', rank: 1, reward: '80 XP + 40 Coins'),
        ],
      ),
      CompetitionModel(
        id: 'weekly_01',
        title: 'Weekly Build-Off',
        category: 'Programming',
        bannerIcon: Icons.rocket_launch_rounded,
        bannerGradient: const [AppColors.orange, Color(0xFFFF5252)],
        difficulty: CompetitionDifficulty.intermediate,
        type: CompetitionType.weekly,
        xpReward: 250,
        coinReward: 150,
        participants: 987,
        endsAt: now.add(const Duration(days: 3)),
        status: CompetitionStatus.live,
        description: 'Ship a small project end-to-end within a week. Best execution wins.',
        rules: ['Runs Monday to Sunday', 'Submit a working demo', 'Peer-reviewed scoring'],
        requirements: ['Level 3+'],
        previousWinners: const [
          CompetitionWinner(username: 'ShipItSam', rank: 1, reward: '300 XP + 200 Coins'),
          CompetitionWinner(username: 'NehaBuilds', rank: 2, reward: '180 XP + 100 Coins'),
        ],
      ),
      CompetitionModel(
        id: 'weekly_02',
        title: 'AI Prompt Masters',
        category: 'AI',
        bannerIcon: Icons.psychology_rounded,
        bannerGradient: const [Color(0xFF42A5F5), Color(0xFF00E676)],
        difficulty: CompetitionDifficulty.intermediate,
        type: CompetitionType.weekly,
        xpReward: 220,
        coinReward: 120,
        participants: 654,
        endsAt: now.add(const Duration(days: 5)),
        status: CompetitionStatus.live,
        description: 'Craft the most creative AI prompt-chains for a themed challenge.',
        rules: ['Runs Monday to Sunday', 'Max 3 submissions', 'Community + mentor scoring'],
        requirements: ['Level 3+'],
        previousWinners: const [
          CompetitionWinner(username: 'PromptPranav', rank: 1, reward: '260 XP + 150 Coins'),
        ],
      ),
      CompetitionModel(
        id: 'monthly_01',
        title: 'Creator of the Month',
        category: 'All Categories',
        bannerIcon: Icons.workspace_premium_rounded,
        bannerGradient: const [AppColors.gold, Color(0xFFFFD54F)],
        difficulty: CompetitionDifficulty.pro,
        type: CompetitionType.monthly,
        xpReward: 1500,
        coinReward: 1000,
        participants: 5320,
        endsAt: now.add(const Duration(days: 14)),
        status: CompetitionStatus.live,
        description: 'The biggest monthly title on SkillVerse — ranked purely on total skill activity across the whole month.',
        rules: ['Ranked by monthly XP + engagement', 'No manual submission needed', 'Winner announced 1st of next month'],
        requirements: ['Level 10+'],
        previousWinners: const [
          CompetitionWinner(username: 'LegendaryLata', rank: 1, reward: '₹10,000 + 2000 XP'),
          CompetitionWinner(username: 'MaxMastery', rank: 2, reward: '₹5,000 + 1200 XP'),
          CompetitionWinner(username: 'SkillSiddharth', rank: 3, reward: '₹2,500 + 700 XP'),
        ],
      ),
    ];
  }
}
