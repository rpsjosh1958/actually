import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/myth_fact.dart';

final factRepositoryProvider = Provider((ref) => FactRepository());

class FactRepository {
  /// The `actuallyFacts` collection is the single source of truth — no local
  /// fallback. Returns an empty list on error (offline, rules not deployed,
  /// etc.) so callers can show a real "couldn't load" state instead of
  /// silently substituting fake content.
  Future<List<MythFact>> load() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('actuallyFacts')
          .get();
      return snap.docs.map(MythFact.fromDoc).toList();
    } catch (e) {
      debugPrint('FactRepository.load failed: $e');
      return [];
    }
  }

  /// Resolves a challenge's fixed `factIds` into full `MythFact`s, preserving
  /// order, so both players see the exact same deck for a versus match.
  Future<List<MythFact>> resolveByIds(List<String> factIds) async {
    final all = await load();
    final byId = {for (final f in all) f.id: f};
    final resolved = <MythFact>[];
    for (final id in factIds) {
      final fact = byId[id];
      if (fact != null) resolved.add(fact);
    }
    if (resolved.length < factIds.length) {
      final unused = all.where((f) => !resolved.contains(f)).toList();
      resolved.addAll(unused.take(factIds.length - resolved.length));
    }
    return resolved;
  }

  /// The ids of facts [uid] has already been served (see
  /// `actuallyProfiles/{uid}/seenFacts`), so a solo/versus deck can exclude
  /// them and no fact repeats until the bank is genuinely exhausted.
  Future<Set<String>> loadSeenFactIds(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('actuallyProfiles')
        .doc(uid)
        .collection('seenFacts')
        .get();
    return snap.docs.map((d) => d.id).toSet();
  }

  /// The full deck, minus whatever [uid] has already seen — falls back to
  /// the unfiltered list once so few facts remain that excluding seen ones
  /// would leave too thin a deck to play with.
  Future<List<MythFact>> loadUnseenFor(
    String uid, {
    int minRemaining = 4,
  }) async {
    final all = await load();
    final seen = await loadSeenFactIds(uid);
    final unseen = all.where((f) => !seen.contains(f.id)).toList();
    return unseen.length >= minRemaining ? unseen : all;
  }

  /// Picks a shared versus deck, preferring facts neither [uidA] nor [uidB]
  /// has seen; pads from the full bank if that pool is short of
  /// [deckSize] rather than ever failing to start a match.
  Future<List<String>> pickVersusDeckIds({
    required String uidA,
    required String uidB,
    required int deckSize,
  }) async {
    final all = await load();
    final seenA = await loadSeenFactIds(uidA);
    final seenB = await loadSeenFactIds(uidB);
    final unseenByBoth = all
        .where((f) => !seenA.contains(f.id) && !seenB.contains(f.id))
        .toList();
    final pool = unseenByBoth.length >= deckSize ? unseenByBoth : all;
    final shuffled = [...pool]..shuffle(Random());
    return shuffled.take(deckSize).map((f) => f.id).toList();
  }
}
