class LeaderboardEntry {
  final int rank;
  final String username;
  final int level;
  final String title; // Beginner/Explorer/Skilled/... from Skill Journey
  final int score;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.level,
    required this.title,
    required this.score,
    this.isCurrentUser = false,
  });
}
