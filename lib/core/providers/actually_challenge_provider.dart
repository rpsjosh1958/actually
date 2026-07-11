import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/fact_repository.dart';
import '../models/actually_challenge.dart';
import 'auth_provider.dart';

// ─── Read providers ───────────────────────────────────────────────────────────

/// IDs of challenges the local user has dismissed (results viewed) — mirrors
/// SORTA-APP's dismissedChallengesProvider.
final dismissedActuallyChallengesProvider = StateProvider<Set<String>>(
  (ref) => {},
);

const _relevantStatuses = [
  ActuallyChallengeStatus.pending,
  ActuallyChallengeStatus.accepted,
  ActuallyChallengeStatus.countdown,
  ActuallyChallengeStatus.active,
  ActuallyChallengeStatus.rematchRequested,
  ActuallyChallengeStatus.complete,
];

/// Status priority: lower index = higher priority (an ongoing game always
/// wins over a fresh incoming invite).
const _statusPriority = [
  ActuallyChallengeStatus.active,
  ActuallyChallengeStatus.countdown,
  ActuallyChallengeStatus.accepted,
  ActuallyChallengeStatus.pending,
  ActuallyChallengeStatus.rematchRequested,
  ActuallyChallengeStatus.complete,
];

/// The one challenge the user is currently engaged in. Rather than a single
/// `arrayContains` query (which would need a composite index), this merges
/// two plain equality queries — challenger side and opponent side — client
/// side, since `actuallyChallenges` has no `playerUids` array field.
final activeActuallyChallengeProvider = StreamProvider<ActuallyChallenge?>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  final dismissed = ref.watch(dismissedActuallyChallengesProvider);
  if (user == null) return Stream.value(null);

  final db = FirebaseFirestore.instance;
  final controller = StreamController<ActuallyChallenge?>();
  List<QueryDocumentSnapshot>? asChallenger;
  List<QueryDocumentSnapshot>? asOpponent;

  void emit() {
    if (asChallenger == null || asOpponent == null) return;
    final challenges = [...asChallenger!, ...asOpponent!]
        .map(ActuallyChallenge.fromDoc)
        .where((c) => !dismissed.contains(c.id))
        .where((c) => _relevantStatuses.contains(c.status))
        .toList();
    if (challenges.isEmpty) {
      controller.add(null);
      return;
    }
    challenges.sort(
      (a, b) => _statusPriority
          .indexOf(a.status)
          .compareTo(_statusPriority.indexOf(b.status)),
    );
    controller.add(challenges.first);
  }

  final subA = db
      .collection('actuallyChallenges')
      .where('challengerUid', isEqualTo: user.uid)
      .snapshots()
      .listen((s) {
        asChallenger = s.docs;
        emit();
      });
  final subB = db
      .collection('actuallyChallenges')
      .where('opponentUid', isEqualTo: user.uid)
      .snapshots()
      .listen((s) {
        asOpponent = s.docs;
        emit();
      });

  ref.onDispose(() {
    subA.cancel();
    subB.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Both players' live progress through the shared deck for a challenge.
final actuallyChallengeAnswersProvider =
    StreamProvider.family<Map<String, ActuallyChallengeProgress>, String>((
      ref,
      challengeId,
    ) {
      return FirebaseFirestore.instance
          .collection('actuallyChallenges')
          .doc(challengeId)
          .collection('answers')
          .snapshots()
          .map(
            (s) => {
              for (final doc in s.docs)
                doc.id: ActuallyChallengeProgress.fromDoc(doc),
            },
          );
    });

// ─── Mutations ────────────────────────────────────────────────────────────────

final actuallyChallengeActionsProvider =
    AsyncNotifierProvider<ActuallyChallengeActions, void>(
      ActuallyChallengeActions.new,
    );

/// Mirrors SORTA-APP's `ChallengeActions` (lib/core/providers/challenge_provider.dart)
/// 1:1, retargeted at `actuallyChallenges` and a swipe-deck (`factIds`)
/// instead of a rank-order question set.
class ActuallyChallengeActions extends AsyncNotifier<void> {
  final _db = FirebaseFirestore.instance;
  static const _deckSize = 12;

  @override
  Future<void> build() async {}

  /// Returns null on success, error message on failure.
  Future<String?> sendChallenge(String opponentUsername) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return 'Not signed in';

    final username = opponentUsername.trim();
    if (username.isEmpty) return 'Enter a username';

    final snap = await _db
        .collection('users')
        .where('displayName', isEqualTo: username)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return 'No player found with that username';

    final opponentDoc = snap.docs.first;
    final opponentUid = opponentDoc.id;
    if (opponentUid == user.uid) return "You can't challenge yourself";
    final opponentName =
        opponentDoc.data()['displayName'] as String? ?? 'Player';

    final allFacts = await ref.read(factRepositoryProvider).load();
    if (allFacts.length < _deckSize) return 'Not enough facts available';
    final factIds = await ref
        .read(factRepositoryProvider)
        .pickVersusDeckIds(
          uidA: user.uid,
          uidB: opponentUid,
          deckSize: _deckSize,
        );

    await _db.collection('actuallyChallenges').doc().set({
      'challengerUid': user.uid,
      'challengerName': user.displayName ?? 'Player',
      'opponentUid': opponentUid,
      'opponentName': opponentName,
      'status': 'pending',
      'factIds': factIds,
      'finishedUids': [],
      'challengerReady': false,
      'opponentReady': false,
      'createdAt': FieldValue.serverTimestamp(),
      'startedAt': null,
      'rematchRequestedBy': null,
    });

    return null;
  }

  Future<void> acceptChallenge(String challengeId) async {
    await _db.collection('actuallyChallenges').doc(challengeId).update({
      'status': 'accepted',
    });
  }

  Future<void> declineChallenge(String challengeId) async {
    await _db.collection('actuallyChallenges').doc(challengeId).update({
      'status': 'declined',
    });
  }

  Future<void> setReady(String challengeId, bool amChallenger) async {
    final docRef = _db.collection('actuallyChallenges').doc(challengeId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final d = snap.data()!;
      final updates = <String, dynamic>{};
      if (amChallenger) {
        updates['challengerReady'] = true;
        if (d['opponentReady'] == true) updates['status'] = 'countdown';
      } else {
        updates['opponentReady'] = true;
        if (d['challengerReady'] == true) updates['status'] = 'countdown';
      }
      tx.update(docRef, updates);
    });
  }

  Future<void> startGame(String challengeId) async {
    await _db.collection('actuallyChallenges').doc(challengeId).update({
      'status': 'active',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Called after every card so the opponent's live score view updates, and
  /// again with `completed: true` once the player exhausts their deck.
  Future<void> submitProgress(
    String challengeId,
    String myUid, {
    required int correct,
    required int answered,
    bool completed = false,
  }) async {
    final challengeRef = _db.collection('actuallyChallenges').doc(challengeId);
    final answerRef = challengeRef.collection('answers').doc(myUid);

    await answerRef.set({
      'correct': correct,
      'answered': answered,
      if (completed) 'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!completed) return;

    await _db.runTransaction((tx) async {
      final snap = await tx.get(challengeRef);
      if (!snap.exists) return;
      final finished = List<String>.from(snap.data()?['finishedUids'] ?? []);
      if (finished.contains(myUid)) return;
      finished.add(myUid);
      final updates = <String, dynamic>{
        'finishedUids': FieldValue.arrayUnion([myUid]),
      };
      if (finished.length >= 2) updates['status'] = 'complete';
      tx.update(challengeRef, updates);
    });
  }

  Future<void> requestRematch(String challengeId, String myUid) async {
    final docRef = _db.collection('actuallyChallenges').doc(challengeId);
    final snap = await docRef.get();
    final d = snap.data()!;
    final other = d['rematchRequestedBy'] as String?;

    if (other != null && other != myUid) {
      await _createRematch(d);
    } else {
      await docRef.update({
        'rematchRequestedBy': myUid,
        'status': 'rematch_requested',
      });
    }
  }

  Future<void> _createRematch(Map<String, dynamic> old) async {
    final factIds = await ref
        .read(factRepositoryProvider)
        .pickVersusDeckIds(
          uidA: old['challengerUid'] as String,
          uidB: old['opponentUid'] as String,
          deckSize: _deckSize,
        );

    await _db.collection('actuallyChallenges').doc().set({
      'challengerUid': old['challengerUid'],
      'challengerName': old['challengerName'],
      'opponentUid': old['opponentUid'],
      'opponentName': old['opponentName'],
      'status': 'accepted',
      'factIds': factIds,
      'finishedUids': [],
      'challengerReady': false,
      'opponentReady': false,
      'createdAt': FieldValue.serverTimestamp(),
      'startedAt': null,
      'rematchRequestedBy': null,
    });
  }

  Future<void> cancelChallenge(String challengeId) async {
    await _db.collection('actuallyChallenges').doc(challengeId).update({
      'status': 'declined',
    });
  }

  /// Locally removes the completed/declined challenge from view (no write).
  void dismiss(String challengeId) {
    ref
        .read(dismissedActuallyChallengesProvider.notifier)
        .update((s) => {...s, challengeId});
  }
}
