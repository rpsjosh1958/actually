import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/actually_profile.dart';
import '../../../core/models/leaderboard_entry.dart';
import '../../../core/providers/auth_provider.dart';

const _pageSize = 25;

/// One page's worth of ranked entries plus what's needed to fetch the next
/// page — [lastDoc] is the Firestore cursor `loadMore()` starts after.
class LeaderboardPage {
  final List<LeaderboardEntry> entries;
  final bool hasMore;
  final bool isLoadingMore;
  final DocumentSnapshot? lastDoc;

  const LeaderboardPage({
    required this.entries,
    required this.hasMore,
    this.isLoadingMore = false,
    this.lastDoc,
  });

  LeaderboardPage copyWith({
    List<LeaderboardEntry>? entries,
    bool? hasMore,
    bool? isLoadingMore,
    DocumentSnapshot? lastDoc,
  }) {
    return LeaderboardPage(
      entries: entries ?? this.entries,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }
}

final leaderboardProvider =
    AsyncNotifierProvider<LeaderboardViewModel, LeaderboardPage>(
      LeaderboardViewModel.new,
    );

/// Paginates `actuallyProfiles` by `bestStreak` desc, 25 at a time, via a
/// Firestore document cursor — a one-shot `.limit()` query can never show
/// more than its cap, so ranks past 25 need `startAfterDocument` instead.
/// Trades the old StreamProvider's live updates for a stable, explicit
/// "load more" — reasonable for a leaderboard, which doesn't need
/// per-second reactivity the way an in-match score does.
class LeaderboardViewModel extends AsyncNotifier<LeaderboardPage> {
  @override
  Future<LeaderboardPage> build() => _fetchPage();

  Future<LeaderboardPage> _fetchPage({DocumentSnapshot? startAfter}) async {
    final currentUid = ref.read(currentUserProvider)?.uid;
    var query = FirebaseFirestore.instance
        .collection('actuallyProfiles')
        .orderBy('bestStreak', descending: true)
        .limit(_pageSize);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snap = await query.get();
    final priorEntries = startAfter == null
        ? const <LeaderboardEntry>[]
        : (state.asData?.value.entries ?? const []);

    final newEntries = [
      for (final (i, doc) in snap.docs.indexed)
        _toEntry(
          ActuallyProfile.fromDoc(doc),
          priorEntries.length + i + 1,
          currentUid,
        ),
    ];

    return LeaderboardPage(
      entries: [...priorEntries, ...newEntries],
      hasMore: snap.docs.length == _pageSize,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : startAfter,
    );
  }

  LeaderboardEntry _toEntry(ActuallyProfile p, int rank, String? currentUid) {
    return LeaderboardEntry(
      rank: rank,
      uid: p.uid,
      // Avatars aren't customizable within Actually — the seed is always
      // the uid, same default SORTA-APP's signup writes.
      avatarSeed: p.uid,
      displayName: p.uid == currentUid ? "YOU (that's you)" : p.displayName,
      score: p.bestStreak,
      isCurrentUser: p.uid == currentUid,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      state = AsyncData(await _fetchPage(startAfter: current.lastDoc));
    } catch (_) {
      // Keep whatever loaded so far visible; just stop spinning so the
      // player can retry rather than getting stuck on a dead spinner.
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchPage);
  }
}
