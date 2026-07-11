import 'package:cloud_firestore/cloud_firestore.dart';

enum FactSubmissionStatus { pending, approved, rejected }

/// A community-submitted candidate fact awaiting (or having resolved) a
/// vote — lives in `actuallyFactSubmissions/{id}`. Counts/status are only
/// ever mutated by the `actuallyOnFactVoteCreated` Cloud Function.
class ActuallyFactSubmission {
  final String id;
  final String submitterUid;
  final String submitterName;
  final String statement;
  final bool isTrue;
  final String why;
  final String? category;
  final int agreeCount;
  final int disagreeCount;
  final List<String> voterUids;
  final FactSubmissionStatus status;
  final Timestamp? createdAt;
  final Timestamp? resolvedAt;

  const ActuallyFactSubmission({
    required this.id,
    required this.submitterUid,
    required this.submitterName,
    required this.statement,
    required this.isTrue,
    required this.why,
    this.category,
    required this.agreeCount,
    required this.disagreeCount,
    required this.voterUids,
    required this.status,
    this.createdAt,
    this.resolvedAt,
  });

  factory ActuallyFactSubmission.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ActuallyFactSubmission(
      id: doc.id,
      submitterUid: d['submitterUid'] as String? ?? '',
      submitterName: d['submitterName'] as String? ?? 'Player',
      statement: d['statement'] as String? ?? '',
      isTrue: d['isTrue'] as bool? ?? false,
      why: d['why'] as String? ?? '',
      category: d['category'] as String?,
      agreeCount: d['agreeCount'] as int? ?? 0,
      disagreeCount: d['disagreeCount'] as int? ?? 0,
      voterUids: List<String>.from(d['voterUids'] as List? ?? []),
      status: _statusFrom(d['status'] as String? ?? 'pending'),
      createdAt: d['createdAt'] as Timestamp?,
      resolvedAt: d['resolvedAt'] as Timestamp?,
    );
  }

  static FactSubmissionStatus _statusFrom(String s) => switch (s) {
    'approved' => FactSubmissionStatus.approved,
    'rejected' => FactSubmissionStatus.rejected,
    _ => FactSubmissionStatus.pending,
  };

  static const voteThreshold = 10;
}
