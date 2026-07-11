import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/actually_challenge_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/accent_button.dart';
import '../../play/view_model/play_view_model.dart';
import 'answer_review_screen.dart';

class ResultScreen extends ConsumerWidget {
  final VoidCallback onMenu;

  const ResultScreen({super.key, required this.onMenu});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;
    final myUid = ref.watch(currentUserProvider)?.uid;
    final challenge = ref.watch(activeActuallyChallengeProvider).asData?.value;
    final localVersusCorrect = ref.watch(playViewModelProvider).versusCorrect;

    if (challenge == null || myUid == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final opponentName = challenge.opponentNameFor(myUid);
    final opponentUid = challenge.opponentUidFor(myUid);
    final answers =
        ref
            .watch(actuallyChallengeAnswersProvider(challenge.id))
            .asData
            ?.value ??
        const {};
    final myScore = answers[myUid]?.correct ?? localVersusCorrect;
    final oppScore = answers[opponentUid]?.correct ?? 0;

    final wl = myScore > oppScore
        ? 'W'
        : myScore < oppScore
        ? 'L'
        : 'TIE';
    final wlColor = wl == 'W'
        ? colors.accent
        : wl == 'L'
        ? colors.paperText
        : colors.faintText;
    final wlLine = switch (wl) {
      'W' => 'you cooked. no crumbs left.',
      'L' => "you got ratio'd. run it back.",
      _ => 'dead even. rematch, obviously.',
    };
    final total = myScore + oppScore;
    final myPct = total == 0 ? 0.5 : myScore / total;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 32),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      wl,
                      style: textTheme.wordmark.copyWith(
                        fontSize: 160,
                        height: 0.9,
                        color: wlColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      wlLine,
                      style: textTheme.label.copyWith(color: colors.paperText),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'YOU',
                          style: textTheme.label.copyWith(
                            fontSize: 14,
                            color: colors.paperText,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          '$myScore — $oppScore',
                          style: textTheme.headline.copyWith(
                            fontSize: 30,
                            color: colors.paperText,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          opponentName.toUpperCase(),
                          style: textTheme.label.copyWith(
                            fontSize: 14,
                            color: colors.paperText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          height: 12,
                          color: colors.border,
                          alignment: Alignment.centerLeft,
                          child: LayoutBuilder(
                            builder: (context, constraints) => Container(
                              width: constraints.maxWidth * myPct,
                              color: colors.accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AccentButton(
                label: 'REMATCH',
                variant: AccentButtonVariant.accent,
                onTap: () => ref
                    .read(actuallyChallengeActionsProvider.notifier)
                    .requestRematch(challenge.id, myUid),
              ),
              const SizedBox(height: 10),
              AccentButton(
                label: 'REVIEW ANSWERS',
                variant: AccentButtonVariant.outline,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AnswerReviewScreen(
                      onBack: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AccentButton(
                label: 'MENU',
                variant: AccentButtonVariant.outline,
                onTap: () {
                  ref
                      .read(actuallyChallengeActionsProvider.notifier)
                      .dismiss(challenge.id);
                  onMenu();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
