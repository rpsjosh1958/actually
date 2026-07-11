class LeaderboardEntry {
  final int rank;
  final String uid;
  final String avatarSeed;
  final String displayName;
  final int score;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.uid,
    required this.avatarSeed,
    required this.displayName,
    required this.score,
    required this.isCurrentUser,
  });
}
