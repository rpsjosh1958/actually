import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/models/actually_challenge.dart';
import 'core/providers/actually_challenge_provider.dart';
import 'features/gameover/view/gameover_screen.dart';
import 'features/leaderboard/view/leaderboard_screen.dart';
import 'features/menu/view/menu_screen.dart';
import 'features/play/view/play_screen.dart';
import 'features/play/view_model/play_view_model.dart';
import 'features/prematch/view/find_opponent_screen.dart';
import 'features/prematch/view/prematch_screen.dart';
import 'features/result/view/result_screen.dart';

enum AppScreen { menu, play, over, findOpponent, prematch, result, board }

final appShellProvider = NotifierProvider<AppShellViewModel, AppScreen>(
  AppShellViewModel.new,
);

/// The single-page state machine the prototype itself uses — one enum
/// drives which screen widget is shown, rather than pushed Navigator
/// routes. Onboarding runs pre-auth (see main.dart's _AuthGate), so by the
/// time this shell mounts the player has already seen it and lands on menu.
class AppShellViewModel extends Notifier<AppScreen> {
  @override
  AppScreen build() => AppScreen.menu;

  void go(AppScreen screen) => state = screen;
}

/// Maps a live `actuallyChallenges` doc's status to the screen that should
/// be showing it — the single source of truth for versus-zone navigation.
AppScreen _screenForChallengeStatus(ActuallyChallengeStatus? status) =>
    switch (status) {
      null ||
      ActuallyChallengeStatus.pending ||
      ActuallyChallengeStatus.declined => AppScreen.findOpponent,
      ActuallyChallengeStatus.accepted ||
      ActuallyChallengeStatus.countdown => AppScreen.prematch,
      ActuallyChallengeStatus.active => AppScreen.play,
      ActuallyChallengeStatus.complete ||
      ActuallyChallengeStatus.rematchRequested => AppScreen.result,
    };

const _versusZone = {
  AppScreen.findOpponent,
  AppScreen.prematch,
  AppScreen.result,
};

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(appShellProvider);
    final shell = ref.read(appShellProvider.notifier);
    final playVm = ref.read(playViewModelProvider.notifier);
    final playMode = ref.watch(playViewModelProvider.select((s) => s.mode));

    void goToChallengeScreen(ActuallyChallenge? c) {
      final target = _screenForChallengeStatus(c?.status);
      if (target == AppScreen.play && c != null) {
        playVm.startVersusMatch(c.id, c.factIds);
      }
      shell.go(target);
    }

    // Every versus-zone screen (find-opponent, ready-up, live match, result)
    // auto-navigates as the shared challenge doc's status changes, so both
    // players always land on the same screen without polling each other.
    final inVersusZone =
        _versusZone.contains(screen) ||
        (screen == AppScreen.play && playMode == PlayMode.versus);
    if (inVersusZone) {
      ref.listen(activeActuallyChallengeProvider, (prev, next) {
        final c = next.asData?.value;
        final target = _screenForChallengeStatus(c?.status);
        if (target != screen) goToChallengeScreen(c);
      });
    }

    return switch (screen) {
      AppScreen.menu => MenuScreen(
        onStartSolo: () {
          playVm.startSolo();
          shell.go(AppScreen.play);
        },
        onVersus: () => goToChallengeScreen(
          ref.read(activeActuallyChallengeProvider).asData?.value,
        ),
        onLeaderboard: () => shell.go(AppScreen.board),
      ),
      AppScreen.play => PlayScreen(
        onExitToMenu: () => shell.go(AppScreen.menu),
        onGameOver: () => shell.go(AppScreen.over),
      ),
      AppScreen.over => GameOverScreen(
        onRunItBack: () => shell.go(AppScreen.play),
        onMenu: () => shell.go(AppScreen.menu),
      ),
      AppScreen.findOpponent => FindOpponentScreen(
        onBack: () => shell.go(AppScreen.menu),
      ),
      AppScreen.prematch => PrematchScreen(
        onBack: () => shell.go(AppScreen.menu),
      ),
      AppScreen.result => ResultScreen(onMenu: () => shell.go(AppScreen.menu)),
      AppScreen.board => LeaderboardScreen(
        onBack: () => shell.go(AppScreen.menu),
      ),
    };
  }
}
