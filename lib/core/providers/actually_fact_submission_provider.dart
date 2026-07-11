import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/actually_fact_submission.dart';
import 'auth_provider.dart';

/// Resolved (approved/rejected) submissions the submitter has already seen
/// the outcome of — local-only, same shape as
/// `dismissedActuallyChallengesProvider`.
final dismissedResolvedSubmissionsProvider = StateProvider<Set<String>>(
  (ref) => {},
);

const maxPendingSubmissionsPerPlayer = 3;

/// Pending submissions the current player can still vote on — excludes
/// their own and any they've already voted on (via the denormalized
/// `voterUids`, so no extra per-doc read is needed).
final pendingVotesForMeProvider = StreamProvider<List<ActuallyFactSubmission>>((
  ref,
) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value(const []);

  return FirebaseFirestore.instance
      .collection('actuallyFactSubmissions')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map(
        (snap) => snap.docs
            .map(ActuallyFactSubmission.fromDoc)
            .where((s) => s.submitterUid != uid && !s.voterUids.contains(uid))
            .toList(),
      );
});

/// The current player's own submissions, most recent first — drives both
/// the "6/10 agreed" pending status card and the resolved confirmation.
final mySubmissionsProvider = StreamProvider<List<ActuallyFactSubmission>>((
  ref,
) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value(const []);

  return FirebaseFirestore.instance
      .collection('actuallyFactSubmissions')
      .where('submitterUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(5)
      .snapshots()
      .map((snap) => snap.docs.map(ActuallyFactSubmission.fromDoc).toList());
});

final actuallyFactSubmissionActionsProvider = Provider(
  (ref) => ActuallyFactSubmissionActions(ref),
);

class ActuallyFactSubmissionActions {
  final Ref ref;
  ActuallyFactSubmissionActions(this.ref);

  final _db = FirebaseFirestore.instance;

  /// Returns null on success, an error message on failure (including
  /// hitting the pending-submission cap).
  Future<String?> submit({
    required String statement,
    required bool isTrue,
    required String why,
    String? category,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return 'Not signed in';
    if (statement.trim().isEmpty || why.trim().isEmpty) {
      return 'Fill in both the fact and the reason.';
    }

    final pendingCount = await _db
        .collection('actuallyFactSubmissions')
        .where('submitterUid', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    if ((pendingCount.count ?? 0) >= maxPendingSubmissionsPerPlayer) {
      return "You've got $maxPendingSubmissionsPerPlayer facts awaiting a verdict already — wait for one to resolve first.";
    }

    await _db.collection('actuallyFactSubmissions').doc().set({
      'submitterUid': user.uid,
      'submitterName': user.displayName ?? 'Player',
      'statement': statement.trim(),
      'isTrue': isTrue,
      'why': why.trim(),
      'category': category,
      'agreeCount': 0,
      'disagreeCount': 0,
      'voterUids': <String>[],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
    });

    return null;
  }

  Future<void> vote(String submissionId, bool agree) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    await _db
        .collection('actuallyFactSubmissions')
        .doc(submissionId)
        .collection('votes')
        .doc(uid)
        .set({'agree': agree, 'votedAt': FieldValue.serverTimestamp()});
  }

  /// Locally hides a resolved submission's confirmation card (no write).
  void dismissResolved(String submissionId) {
    ref
        .read(dismissedResolvedSubmissionsProvider.notifier)
        .update((s) => {...s, submissionId});
  }
}
