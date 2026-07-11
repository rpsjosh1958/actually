import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/actually_profile.dart';
import 'auth_provider.dart';

final actuallyProfileProvider = StreamProvider<ActuallyProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('actuallyProfiles')
      .doc(user.uid)
      .snapshots()
      .map(
        (snap) => snap.exists
            ? ActuallyProfile.fromDoc(snap)
            : ActuallyProfile.empty(user.uid),
      );
});

final actuallyProfileActionsProvider = Provider(
  (ref) => ActuallyProfileActions(ref),
);

class ActuallyProfileActions {
  final Ref ref;
  ActuallyProfileActions(this.ref);

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('actuallyProfiles').doc(uid);

  /// Idempotent — call once when a user becomes authenticated so bestStreak
  /// reads never hit a missing doc. No-ops if the profile already exists.
  Future<void> bootstrapIfNeeded() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final doc = _doc(user.uid);
    final snap = await doc.get();
    if (snap.exists) return;

    // `user.displayName` (FirebaseAuth's cached User object) is stale right
    // after sign-up — authStateChanges() doesn't re-emit when
    // updateDisplayName() completes, so this would read null and fall back
    // to "Player" for every brand-new account. The shared `users/{uid}` doc
    // is written with the real username in the same signup flow, so it's
    // the reliable source here.
    final sharedUserSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final displayName =
        sharedUserSnap.data()?['displayName'] as String? ??
        user.displayName ??
        'Player';

    await doc.set({
      'uid': user.uid,
      'displayName': displayName,
      'bestStreak': 0,
      'totalGamesPlayed': 0,
      'totalCorrect': 0,
      'totalWrong': 0,
      'totalBattlesPlayed': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Records a completed solo run: bumps bestStreak if it's a new PB, tallies
  /// lifetime correct/wrong, and logs an `actuallyMatches` doc.
  Future<void> recordSoloRun({
    required int finalStreak,
    required int correct,
    required int wrong,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final doc = _doc(user.uid);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final current = snap.exists
          ? ActuallyProfile.fromDoc(snap)
          : ActuallyProfile.empty(user.uid);
      tx.set(doc, {
        'uid': user.uid,
        'displayName': user.displayName ?? current.displayName,
        'bestStreak': finalStreak > current.bestStreak
            ? finalStreak
            : current.bestStreak,
        'totalGamesPlayed': current.totalGamesPlayed + 1,
        'totalCorrect': current.totalCorrect + correct,
        'totalWrong': current.totalWrong + wrong,
        'totalBattlesPlayed': current.totalBattlesPlayed,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await FirebaseFirestore.instance.collection('actuallyMatches').add({
      'uid': user.uid,
      'mode': 'solo',
      'finalStreak': finalStreak,
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Records a completed club battle (Phase 2 — currently simulated, no real
  /// opponents). Tallies lifetime correct/wrong + battle count and logs an
  /// `actuallyMatches` doc; bestStreak is untouched (battle score is
  /// independent of the solo streak).
  Future<void> recordBattle({
    required int myScore,
    required int oppScore,
    required int correct,
    required int wrong,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final result = myScore > oppScore
        ? 'win'
        : myScore < oppScore
        ? 'loss'
        : 'tie';
    final doc = _doc(user.uid);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final current = snap.exists
          ? ActuallyProfile.fromDoc(snap)
          : ActuallyProfile.empty(user.uid);
      tx.set(doc, {
        'uid': user.uid,
        'displayName': user.displayName ?? current.displayName,
        'bestStreak': current.bestStreak,
        'totalGamesPlayed': current.totalGamesPlayed,
        'totalCorrect': current.totalCorrect + correct,
        'totalWrong': current.totalWrong + wrong,
        'totalBattlesPlayed': current.totalBattlesPlayed + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await FirebaseFirestore.instance.collection('actuallyMatches').add({
      'uid': user.uid,
      'mode': 'battle',
      'myScore': myScore,
      'oppScore': oppScore,
      'result': result,
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Records that the player has now played [factId] so it's excluded from
  /// future decks (see `FactRepository.loadUnseenFor`/`pickVersusDeckIds`).
  /// Fire-and-forget from the caller — a dropped write here just means one
  /// fact might repeat sooner, not worth blocking gameplay on.
  Future<void> markFactSeen(String factId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('actuallyProfiles')
        .doc(user.uid)
        .collection('seenFacts')
        .doc(factId)
        .set({});
  }
}
