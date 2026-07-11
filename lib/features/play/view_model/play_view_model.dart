import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/fact_repository.dart';
import '../../../core/models/myth_fact.dart';
import '../../../core/providers/actually_challenge_provider.dart';
import '../../../core/providers/actually_profile_provider.dart';
import '../../../core/providers/auth_provider.dart';

enum PlayMode { solo, versus }

enum CardFace { front, back }

/// Every card, in every mode, must be answered within this many seconds —
/// running out counts the same as a wrong swipe.
const cardDurationSeconds = 10;

/// Sentinel so copyWith can tell "leave committedRight alone" apart from
/// "explicitly set it to null" (needed on every reset).
const _unset = Object();

/// One resolved card, kept around so a versus match can show a post-game
/// "review answers" breakdown of what was right/wrong.
class AnsweredCard {
  final MythFact fact;
  final bool? swipedRight;
  final bool isCorrect;
  final bool timedOut;

  const AnsweredCard({
    required this.fact,
    required this.swipedRight,
    required this.isCorrect,
    required this.timedOut,
  });
}

class PlayState {
  final PlayMode mode;
  final List<MythFact> deck;
  final bool isDeckLoading;
  final int factIndex;
  final CardFace face;
  final double dragDx;
  final bool isDragging;
  final bool? committedRight;
  final bool isCorrect;
  final bool timedOut;
  final bool isGameOver;
  final int streak;
  final int versusCorrect;
  final int versusAnswered;
  final bool isVersusComplete;
  final int cardSecondsRemaining;
  final List<AnsweredCard> history;

  const PlayState({
    required this.mode,
    required this.deck,
    required this.isDeckLoading,
    required this.factIndex,
    required this.face,
    required this.dragDx,
    required this.isDragging,
    required this.committedRight,
    required this.isCorrect,
    required this.timedOut,
    required this.isGameOver,
    required this.streak,
    required this.versusCorrect,
    required this.versusAnswered,
    required this.isVersusComplete,
    required this.cardSecondsRemaining,
    required this.history,
  });

  static const initial = PlayState(
    mode: PlayMode.solo,
    deck: [],
    isDeckLoading: true,
    factIndex: 0,
    face: CardFace.front,
    dragDx: 0,
    isDragging: false,
    committedRight: null,
    isCorrect: false,
    timedOut: false,
    isGameOver: false,
    streak: 0,
    versusCorrect: 0,
    versusAnswered: 0,
    isVersusComplete: false,
    cardSecondsRemaining: cardDurationSeconds,
    history: [],
  );

  MythFact? get currentFact =>
      deck.isEmpty ? null : deck[factIndex % deck.length];

  PlayState copyWith({
    PlayMode? mode,
    List<MythFact>? deck,
    bool? isDeckLoading,
    int? factIndex,
    CardFace? face,
    double? dragDx,
    bool? isDragging,
    Object? committedRight = _unset,
    bool? isCorrect,
    bool? timedOut,
    bool? isGameOver,
    int? streak,
    int? versusCorrect,
    int? versusAnswered,
    bool? isVersusComplete,
    int? cardSecondsRemaining,
    List<AnsweredCard>? history,
  }) {
    return PlayState(
      mode: mode ?? this.mode,
      deck: deck ?? this.deck,
      isDeckLoading: isDeckLoading ?? this.isDeckLoading,
      factIndex: factIndex ?? this.factIndex,
      face: face ?? this.face,
      dragDx: dragDx ?? this.dragDx,
      isDragging: isDragging ?? this.isDragging,
      committedRight: identical(committedRight, _unset)
          ? this.committedRight
          : committedRight as bool?,
      isCorrect: isCorrect ?? this.isCorrect,
      timedOut: timedOut ?? this.timedOut,
      isGameOver: isGameOver ?? this.isGameOver,
      streak: streak ?? this.streak,
      versusCorrect: versusCorrect ?? this.versusCorrect,
      versusAnswered: versusAnswered ?? this.versusAnswered,
      isVersusComplete: isVersusComplete ?? this.isVersusComplete,
      cardSecondsRemaining: cardSecondsRemaining ?? this.cardSecondsRemaining,
      history: history ?? this.history,
    );
  }
}

final playViewModelProvider = NotifierProvider<PlayViewModel, PlayState>(
  PlayViewModel.new,
);

/// Drives the shared solo/versus card mechanic. One notifier for both modes
/// — they share the entire drag/flip/commit state machine and only diverge
/// in what a wrong swipe (or timeout) does and whether progress is reported
/// to a live `actuallyChallenges` doc.
class PlayViewModel extends Notifier<PlayState> {
  Timer? _cardTimer;
  Timer? _autoAdvanceTimer;
  final _rng = Random();
  int _correctCount = 0;
  int _wrongCount = 0;
  String? _challengeId;
  int _loadGeneration = 0;

  @override
  PlayState build() {
    ref.onDispose(() {
      _cardTimer?.cancel();
      _autoAdvanceTimer?.cancel();
    });
    _loadDeckInto(PlayMode.solo);
    return PlayState.initial;
  }

  /// Facts the current player hasn't already played, so a fresh run never
  /// repeats one until the bank is genuinely exhausted.
  Future<List<MythFact>> _loadDeckExcludingSeen() async {
    final repo = ref.read(factRepositoryProvider);
    final uid = ref.read(currentUserProvider)?.uid;
    return uid != null ? repo.loadUnseenFor(uid) : repo.load();
  }

  /// Loads a fresh solo deck and reveals it only once it's ready — never
  /// shows a placeholder/stale card that then gets swapped out from under
  /// the player. [generation] guards against a stale in-flight load (e.g.
  /// from build()) overwriting a deck a later startSolo() call already set.
  Future<void> _loadDeckInto(PlayMode mode) async {
    final generation = ++_loadGeneration;
    final facts = await _loadDeckExcludingSeen();
    if (generation != _loadGeneration) return;
    state = state.copyWith(deck: _shuffled(facts), isDeckLoading: false);
  }

  List<MythFact> _shuffled(List<MythFact> facts) => [...facts]..shuffle(_rng);

  void _startCardTimer() {
    _cardTimer?.cancel();
    state = state.copyWith(cardSecondsRemaining: cardDurationSeconds);
    _cardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.face == CardFace.back) {
        timer.cancel();
        return;
      }
      final t = state.cardSecondsRemaining - 1;
      if (t <= 0) {
        timer.cancel();
        _timeout();
      } else {
        state = state.copyWith(cardSecondsRemaining: t);
      }
    });
  }

  Future<void> startSolo() async {
    _autoAdvanceTimer?.cancel();
    _cardTimer?.cancel();
    _correctCount = 0;
    _wrongCount = 0;
    _challengeId = null;
    // Clear the deck instead of reshuffling the old one — a solo run never
    // shows a card until its real, freshly-filtered deck is ready.
    state = state.copyWith(
      mode: PlayMode.solo,
      deck: const [],
      isDeckLoading: true,
      factIndex: 0,
      face: CardFace.front,
      dragDx: 0,
      isDragging: false,
      committedRight: null,
      isCorrect: false,
      timedOut: false,
      isGameOver: false,
      streak: 0,
      history: const [],
    );

    final generation = ++_loadGeneration;
    final facts = await _loadDeckExcludingSeen();
    if (generation != _loadGeneration) return;
    state = state.copyWith(deck: _shuffled(facts), isDeckLoading: false);
    _startCardTimer();
  }

  /// [factIds] is the challenge's fixed shared deck — both players resolve
  /// the same ids so they see identical cards in identical order.
  Future<void> startVersusMatch(
    String challengeId,
    List<String> factIds,
  ) async {
    _autoAdvanceTimer?.cancel();
    _cardTimer?.cancel();
    _challengeId = challengeId;
    state = state.copyWith(
      mode: PlayMode.versus,
      deck: const [],
      isDeckLoading: true,
      factIndex: 0,
      face: CardFace.front,
      dragDx: 0,
      isDragging: false,
      committedRight: null,
      isCorrect: false,
      timedOut: false,
      isVersusComplete: false,
      versusCorrect: 0,
      versusAnswered: 0,
      history: const [],
    );

    final generation = ++_loadGeneration;
    final deck = await ref.read(factRepositoryProvider).resolveByIds(factIds);
    if (generation != _loadGeneration) return;
    state = state.copyWith(deck: deck, isDeckLoading: false);
    _startCardTimer();
  }

  void _timeout() {
    if (state.face == CardFace.back) return;
    _applyOutcome(swipedRight: null, isCorrect: false, timedOut: true);
  }

  /// Drag and the CAP/BASED tap buttons both funnel through here — one
  /// source of truth for "what happens on a decision."
  void commit(bool swipedRight) {
    final fact = state.currentFact;
    if (state.face == CardFace.back || fact == null) return;
    _applyOutcome(
      swipedRight: swipedRight,
      isCorrect: swipedRight == fact.isTrue,
      timedOut: false,
    );
  }

  void _applyOutcome({
    required bool? swipedRight,
    required bool isCorrect,
    required bool timedOut,
  }) {
    _cardTimer?.cancel();

    final seenFact = state.currentFact;
    if (seenFact != null) {
      ref.read(actuallyProfileActionsProvider).markFactSeen(seenFact.id);
    }

    if (isCorrect) {
      _correctCount += 1;
    } else {
      _wrongCount += 1;
    }

    var streak = state.streak;
    var isGameOver = state.isGameOver;
    var versusCorrect = state.versusCorrect;
    var versusAnswered = state.versusAnswered;
    var isVersusComplete = state.isVersusComplete;

    if (state.mode == PlayMode.solo) {
      if (isCorrect) {
        streak += 1;
      } else {
        isGameOver = true;
        ref
            .read(actuallyProfileActionsProvider)
            .recordSoloRun(
              finalStreak: streak,
              correct: _correctCount,
              wrong: _wrongCount,
            );
      }
    } else {
      versusAnswered += 1;
      if (isCorrect) versusCorrect += 1;
      isVersusComplete = versusAnswered >= state.deck.length;

      final challengeId = _challengeId;
      final uid = ref.read(currentUserProvider)?.uid;
      if (challengeId != null && uid != null) {
        ref
            .read(actuallyChallengeActionsProvider.notifier)
            .submitProgress(
              challengeId,
              uid,
              correct: versusCorrect,
              answered: versusAnswered,
              completed: isVersusComplete,
            );
      }
    }

    final history = [
      ...state.history,
      if (seenFact != null)
        AnsweredCard(
          fact: seenFact,
          swipedRight: swipedRight,
          isCorrect: isCorrect,
          timedOut: timedOut,
        ),
    ];

    state = state.copyWith(
      face: CardFace.back,
      isDragging: false,
      dragDx: 0,
      committedRight: swipedRight,
      isCorrect: isCorrect,
      timedOut: timedOut,
      streak: streak,
      isGameOver: isGameOver,
      versusCorrect: versusCorrect,
      versusAnswered: versusAnswered,
      isVersusComplete: isVersusComplete,
      history: history,
    );

    if (state.mode == PlayMode.versus && !isVersusComplete) {
      _autoAdvanceTimer?.cancel();
      _autoAdvanceTimer = Timer(const Duration(milliseconds: 950), () {
        if (state.face == CardFace.back) advance();
      });
    }
  }

  void advance() {
    if (state.isGameOver || state.face != CardFace.back) return;
    if (state.mode == PlayMode.versus && state.isVersusComplete) return;

    var nextIndex = state.factIndex + 1;
    var deck = state.deck;
    if (state.mode == PlayMode.solo &&
        deck.isNotEmpty &&
        nextIndex % deck.length == 0) {
      deck = _shuffled(deck);
      nextIndex = 0;
    }

    state = state.copyWith(
      factIndex: nextIndex,
      deck: deck,
      face: CardFace.front,
      dragDx: 0,
      isDragging: false,
      committedRight: null,
      isCorrect: false,
      timedOut: false,
    );
    _startCardTimer();
  }

  void onDragUpdate(double dx) {
    if (state.face == CardFace.back) return;
    state = state.copyWith(dragDx: dx, isDragging: true);
  }

  void onDragEnd() {
    if (!state.isDragging) return;
    if (state.dragDx.abs() >= 95) {
      commit(state.dragDx > 0);
    } else {
      state = state.copyWith(dragDx: 0, isDragging: false);
    }
  }
}
