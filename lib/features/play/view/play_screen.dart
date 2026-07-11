import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/actually_challenge.dart';
import '../../../core/providers/actually_challenge_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/accent_button.dart';
import '../../../core/widgets/bouncing_dots.dart';
import '../view_model/play_view_model.dart';
import 'widgets/myth_card.dart';

class PlayScreen extends ConsumerWidget {
  final VoidCallback onExitToMenu;
  final VoidCallback onGameOver;

  const PlayScreen({
    super.key,
    required this.onExitToMenu,
    required this.onGameOver,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;
    final state = ref.watch(playViewModelProvider);
    final vm = ref.read(playViewModelProvider.notifier);
    final myUid = ref.watch(currentUserProvider)?.uid;

    final isVersus = state.mode == PlayMode.versus;
    // Navigating away once the match completes is handled centrally by
    // app_shell.dart (which watches this same provider for the whole versus
    // zone) — this screen only reads it for the live opponent score/name.
    final challenge = isVersus
        ? ref.watch(activeActuallyChallengeProvider).asData?.value
        : null;

    final opponentName = (challenge != null && myUid != null)
        ? challenge.opponentNameFor(myUid)
        : '';
    final opponentUid = (challenge != null && myUid != null)
        ? challenge.opponentUidFor(myUid)
        : null;
    final opponentCorrect = (challenge != null && opponentUid != null)
        ? ref
                  .watch(actuallyChallengeAnswersProvider(challenge.id))
                  .asData
                  ?.value[opponentUid]
                  ?.correct ??
              0
        : 0;

    // Game over/waiting-for-opponent don't jump straight to the next screen
    // — the flipped card (verdict + why) stays up until the player taps to
    // continue, same as every other card.
    final onContinueTap =
        state.mode == PlayMode.solo && state.face == CardFace.back
        ? (state.isGameOver ? onGameOver : vm.advance)
        : null;

    final waitingForOpponent =
        isVersus &&
        state.isVersusComplete &&
        challenge?.status != ActuallyChallengeStatus.complete;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: onExitToMenu,
                        child: Text(
                          '←',
                          style: textTheme.headline.copyWith(
                            fontSize: 22,
                            color: colors.paperText,
                          ),
                        ),
                      ),
                      if (!isVersus)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'STREAK',
                              style: textTheme.caption.copyWith(
                                color: colors.faintText,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${state.streak}',
                              style: textTheme.headline.copyWith(
                                fontSize: 34,
                                color: colors.paperText,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'YOU  ',
                              style: textTheme.caption.copyWith(
                                color: colors.faintText,
                              ),
                            ),
                            Text(
                              '${state.versusCorrect}',
                              style: textTheme.headline.copyWith(
                                fontSize: 24,
                                color: colors.paperText,
                              ),
                            ),
                            Text(
                              '  —  ',
                              style: textTheme.caption.copyWith(
                                color: colors.faintText,
                              ),
                            ),
                            Text(
                              '$opponentCorrect',
                              style: textTheme.headline.copyWith(
                                fontSize: 24,
                                color: colors.paperText,
                              ),
                            ),
                            Text(
                              '  $opponentName',
                              style: textTheme.caption.copyWith(
                                color: colors.faintText,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 18,
                    ),
                    child: Center(
                      child: state.isDeckLoading
                          ? BouncingDots(color: colors.accent)
                          : state.deck.isEmpty
                          ? _NoFactsAvailable(
                              colors: colors,
                              textTheme: textTheme,
                              onRetry: () {
                                if (isVersus && challenge != null) {
                                  vm.startVersusMatch(
                                    challenge.id,
                                    challenge.factIds,
                                  );
                                } else {
                                  vm.startSolo();
                                }
                              },
                            )
                          : MythCard(onContinueTap: onContinueTap),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 0, 26, 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoundButton(
                        label: 'CAP',
                        background: colors.paperBg,
                        foreground: colors.paperText,
                        onTap: () => vm.commit(false),
                      ),
                      const SizedBox(width: 26),
                      Text(
                        'OR SWIPE',
                        style: textTheme.caption.copyWith(
                          color: colors.faintText,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 26),
                      _RoundButton(
                        label: 'BASED',
                        background: colors.accent,
                        foreground: colors.paperText,
                        onTap: () => vm.commit(true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (waitingForOpponent)
              _WaitingOverlay(
                colors: colors,
                textTheme: textTheme,
                opponentName: opponentName,
              ),
          ],
        ),
      ),
    );
  }
}

class _NoFactsAvailable extends StatelessWidget {
  final AppColorsExtension colors;
  final AppTextThemeExtension textTheme;
  final VoidCallback onRetry;

  const _NoFactsAvailable({
    required this.colors,
    required this.textTheme,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "couldn't load facts. check your connection.",
          textAlign: TextAlign.center,
          style: textTheme.label.copyWith(color: colors.mutedText),
        ),
        const SizedBox(height: 18),
        AccentButton(
          label: 'RETRY',
          variant: AccentButtonVariant.outline,
          onTap: onRetry,
        ),
      ],
    );
  }
}

class _WaitingOverlay extends StatelessWidget {
  final AppColorsExtension colors;
  final AppTextThemeExtension textTheme;
  final String opponentName;

  const _WaitingOverlay({
    required this.colors,
    required this.textTheme,
    required this.opponentName,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: colors.background.withValues(alpha: 0.94),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'waiting for $opponentName to finish…',
              style: textTheme.label.copyWith(color: colors.paperText),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _RoundButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).appTextTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: textTheme.button.copyWith(fontSize: 13, color: foreground),
        ),
      ),
    );
  }
}
