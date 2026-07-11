import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../play/view_model/play_view_model.dart';

/// Post-match breakdown of every card in a versus deck — lets a player see
/// exactly which facts they got wrong once the match (and its 10s-per-card
/// pace) is over.
class AnswerReviewScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const AnswerReviewScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;
    final history = ref.watch(playViewModelProvider).history;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onBack,
                child: Text(
                  '←',
                  style: textTheme.headline.copyWith(
                    fontSize: 22,
                    color: colors.paperText,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'REVIEW ANSWERS',
                style: textTheme.headline.copyWith(
                  fontSize: 24,
                  color: colors.paperText,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      _ReviewCard(index: i + 1, card: history[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int index;
  final AnsweredCard card;

  const _ReviewCard({required this.index, required this.card});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;

    final (badge, badgeColor) = card.timedOut
        ? ('TOO SLOW', colors.danger)
        : card.isCorrect
        ? ('✓ CORRECT', colors.accent)
        : ('✗ WRONG', colors.danger);

    final yourAnswer = card.timedOut
        ? "didn't answer"
        : (card.swipedRight == true ? 'BASED' : 'CAP');
    final correctAnswer = card.fact.isTrue ? 'BASED' : 'CAP';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.paperBg,
        border: Border.all(
          color: card.isCorrect && !card.timedOut
              ? colors.accent.withValues(alpha: 0.4)
              : colors.border,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FACT №$index',
                style: textTheme.caption.copyWith(color: colors.faintText),
              ),
              Text(
                badge,
                style: textTheme.caption.copyWith(color: badgeColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            card.fact.statement,
            style: textTheme.body.copyWith(
              fontSize: 15,
              color: colors.paperText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'you said $yourAnswer · answer was $correctAnswer',
            style: textTheme.caption.copyWith(color: colors.mutedText),
          ),
          const SizedBox(height: 6),
          Text(
            card.fact.why,
            style: textTheme.bodyRegular.copyWith(
              fontSize: 12.5,
              color: colors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
