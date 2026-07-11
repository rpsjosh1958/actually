import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/actually_profile.dart';
import '../../../core/models/leaderboard_entry.dart';
import '../../../core/providers/auth_provider.dart';

final leaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  final currentUid = ref.watch(currentUserProvider)?.uid;

  return FirebaseFirestore.instance
      .collection('actuallyProfiles')
      .orderBy('bestStreak', descending: true)
      .limit(25)
      .snapshots()
      .map((snap) {
        final profiles = snap.docs.map(ActuallyProfile.fromDoc).toList();
        return [
          for (final (i, p) in profiles.indexed)
            LeaderboardEntry(
              rank: i + 1,
              uid: p.uid,
              // Avatars aren't customizable within Actually — the seed is
              // always the uid, same default SORTA-APP's signup writes.
              avatarSeed: p.uid,
              displayName: p.uid == currentUid
                  ? "YOU (that's you)"
                  : p.displayName,
              score: p.bestStreak,
              isCurrentUser: p.uid == currentUid,
            ),
        ];
      });
});
