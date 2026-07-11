import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/actually_challenge.dart';
import '../../../core/providers/actually_challenge_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/accent_button.dart';

/// Post-accept ready-up screen: shows the real opponent, a READY button,
/// waits for both sides, then a 3-2-1 countdown before handing off to play
/// — the same beat as SORTA-APP's versus_screen.dart countdown.
class PrematchScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const PrematchScreen({super.key, required this.onBack});

  @override
  ConsumerState<PrematchScreen> createState() => _PrematchScreenState();
}

class _PrematchScreenState extends ConsumerState<PrematchScreen> {
  int? _countdown;
  Timer? _countdownTimer;
  bool _startGameCalled = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _beginCountdown(String challengeId) {
    if (_countdownTimer != null) return;
    setState(() => _countdown = 3);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = (_countdown ?? 1) - 1;
      if (next <= 0) {
        timer.cancel();
        setState(() => _countdown = 0);
        if (!_startGameCalled) {
          _startGameCalled = true;
          ref
              .read(actuallyChallengeActionsProvider.notifier)
              .startGame(challengeId);
        }
      } else {
        setState(() => _countdown = next);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;
    final myUid = ref.watch(currentUserProvider)?.uid;
    final challenge = ref.watch(activeActuallyChallengeProvider).asData?.value;

    if (challenge == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // The active->play transition itself is handled centrally by
    // app_shell.dart; this listener only needs to kick off the local 3-2-1
    // countdown the moment both players are ready.
    ref.listen(activeActuallyChallengeProvider, (prev, next) {
      final c = next.asData?.value;
      if (c != null && c.status == ActuallyChallengeStatus.countdown) {
        _beginCountdown(c.id);
      }
    });

    if (challenge.status == ActuallyChallengeStatus.countdown) {
      if (_countdown == null) _beginCountdown(challenge.id);
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Text(
            _countdown == 0 ? 'GO!' : '${_countdown ?? 3}',
            style: textTheme.wordmark.copyWith(
              fontSize: 96,
              color: colors.paperText,
            ),
          ),
        ),
      );
    }

    final amChallenger = myUid == challenge.challengerUid;
    final iAmReady = challenge.isReadyFor(myUid ?? '');
    final opponentName = challenge.opponentNameFor(myUid ?? '');

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Text(
                  '←',
                  style: textTheme.headline.copyWith(
                    fontSize: 22,
                    color: colors.paperText,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LIVE VERSUS MATCH',
                          style: textTheme.caption.copyWith(
                            color: colors.mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'YOU',
                      style: textTheme.headline.copyWith(
                        fontSize: 30,
                        color: colors.paperText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'VS',
                      style: textTheme.headline.copyWith(
                        fontSize: 22,
                        color: colors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      opponentName,
                      style: textTheme.headline.copyWith(
                        fontSize: 30,
                        color: colors.paperText,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Text(
                        'same ${challenge.factIds.length} facts, 10 seconds each. most correct swipes wins.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyRegular.copyWith(
                          color: colors.mutedText,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AccentButton(
                label: iAmReady ? 'WAITING FOR $opponentName…' : "I'M READY",
                variant: AccentButtonVariant.ink,
                onTap: iAmReady
                    ? null
                    : () => ref
                          .read(actuallyChallengeActionsProvider.notifier)
                          .setReady(challenge.id, amChallenger),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
