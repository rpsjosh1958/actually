import 'package:cloud_firestore/cloud_firestore.dart';

/// Actually's own gameplay profile — lives in `actuallyProfiles/{uid}`,
/// entirely separate from SORTA's `users/{uid}` doc.
class ActuallyProfile {
  final String uid;
  // Denormalized from the shared `users/{uid}.displayName` at write time so
  // the leaderboard query never needs an N+1 join against `users`. May lag
  // slightly behind a name change made in SORTA-APP — acceptable for a
  // cosmetic leaderboard label.
  final String displayName;
  final int bestStreak;
  final int totalGamesPlayed;
  final int totalCorrect;
  final int totalWrong;
  final int totalBattlesPlayed;

  const ActuallyProfile({
    required this.uid,
    required this.displayName,
    required this.bestStreak,
    required this.totalGamesPlayed,
    required this.totalCorrect,
    required this.totalWrong,
    required this.totalBattlesPlayed,
  });

  factory ActuallyProfile.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? const {};
    return ActuallyProfile(
      uid: doc.id,
      displayName: d['displayName'] as String? ?? 'Player',
      bestStreak: d['bestStreak'] as int? ?? 0,
      totalGamesPlayed: d['totalGamesPlayed'] as int? ?? 0,
      totalCorrect: d['totalCorrect'] as int? ?? 0,
      totalWrong: d['totalWrong'] as int? ?? 0,
      totalBattlesPlayed: d['totalBattlesPlayed'] as int? ?? 0,
    );
  }

  static ActuallyProfile empty(String uid) => ActuallyProfile(
    uid: uid,
    displayName: 'Player',
    bestStreak: 0,
    totalGamesPlayed: 0,
    totalCorrect: 0,
    totalWrong: 0,
    totalBattlesPlayed: 0,
  );
}
