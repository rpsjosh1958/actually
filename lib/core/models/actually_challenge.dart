import 'package:cloud_firestore/cloud_firestore.dart';

enum ActuallyChallengeStatus {
  pending,
  accepted,
  countdown,
  active,
  complete,
  rematchRequested,
  declined,
}

/// A 1v1 online versus match — mirrors SORTA-APP's `Challenge` model
/// (lib/core/models/challenge.dart) but the shared payload is a fixed deck
/// of `factIds` (a swipe deck) instead of a set of rank-order questions.
class ActuallyChallenge {
  final String id;
  final String challengerUid;
  final String challengerName;
  final String opponentUid;
  final String opponentName;
  final ActuallyChallengeStatus status;
  final List<String> factIds;
  final List<String> finishedUids;
  final bool challengerReady;
  final bool opponentReady;
  final Timestamp? createdAt;
  final Timestamp? startedAt;
  final String? rematchRequestedBy;

  const ActuallyChallenge({
    required this.id,
    required this.challengerUid,
    required this.challengerName,
    required this.opponentUid,
    required this.opponentName,
    required this.status,
    required this.factIds,
    this.finishedUids = const [],
    required this.challengerReady,
    required this.opponentReady,
    this.createdAt,
    this.startedAt,
    this.rematchRequestedBy,
  });

  factory ActuallyChallenge.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ActuallyChallenge(
      id: doc.id,
      challengerUid: d['challengerUid'] as String? ?? '',
      challengerName: d['challengerName'] as String? ?? 'Player',
      opponentUid: d['opponentUid'] as String? ?? '',
      opponentName: d['opponentName'] as String? ?? 'Player',
      status: _statusFrom(d['status'] as String? ?? 'pending'),
      factIds: List<String>.from(d['factIds'] as List? ?? []),
      finishedUids: List<String>.from(d['finishedUids'] as List? ?? []),
      challengerReady: d['challengerReady'] as bool? ?? false,
      opponentReady: d['opponentReady'] as bool? ?? false,
      createdAt: d['createdAt'] as Timestamp?,
      startedAt: d['startedAt'] as Timestamp?,
      rematchRequestedBy: d['rematchRequestedBy'] as String?,
    );
  }

  static ActuallyChallengeStatus _statusFrom(String s) => switch (s) {
    'accepted' => ActuallyChallengeStatus.accepted,
    'countdown' => ActuallyChallengeStatus.countdown,
    'active' => ActuallyChallengeStatus.active,
    'complete' => ActuallyChallengeStatus.complete,
    'rematch_requested' => ActuallyChallengeStatus.rematchRequested,
    'declined' => ActuallyChallengeStatus.declined,
    _ => ActuallyChallengeStatus.pending,
  };

  static String statusString(ActuallyChallengeStatus s) => switch (s) {
    ActuallyChallengeStatus.accepted => 'accepted',
    ActuallyChallengeStatus.countdown => 'countdown',
    ActuallyChallengeStatus.active => 'active',
    ActuallyChallengeStatus.complete => 'complete',
    ActuallyChallengeStatus.rematchRequested => 'rematch_requested',
    ActuallyChallengeStatus.declined => 'declined',
    _ => 'pending',
  };

  bool involves(String uid) => uid == challengerUid || uid == opponentUid;

  String opponentNameFor(String myUid) =>
      myUid == challengerUid ? opponentName : challengerName;

  String opponentUidFor(String myUid) =>
      myUid == challengerUid ? opponentUid : challengerUid;

  bool isReadyFor(String myUid) =>
      myUid == challengerUid ? challengerReady : opponentReady;

  bool get bothReady => challengerReady && opponentReady;
}

/// One player's live progress through the shared `factIds` deck — the
/// running `correct` count is what the opponent's live score reads.
class ActuallyChallengeProgress {
  final int correct;
  final int answered;
  final bool isComplete;

  const ActuallyChallengeProgress({
    required this.correct,
    required this.answered,
    required this.isComplete,
  });

  factory ActuallyChallengeProgress.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? const {};
    return ActuallyChallengeProgress(
      correct: d['correct'] as int? ?? 0,
      answered: d['answered'] as int? ?? 0,
      isComplete: d['completedAt'] != null,
    );
  }

  static const zero = ActuallyChallengeProgress(
    correct: 0,
    answered: 0,
    isComplete: false,
  );
}
