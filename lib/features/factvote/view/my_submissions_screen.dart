import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/actually_fact_submission.dart';
import '../../../core/providers/actually_fact_submission_provider.dart';
import '../../../core/theme/app_theme.dart';

/// The submitter's own view of their facts — live agree/disagree tallies
/// while pending, and a one-time confirmation once a Cloud Function
/// resolves it (approved into the game, or rejected).
class MySubmissionsScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const MySubmissionsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;
    final dismissed = ref.watch(dismissedResolvedSubmissionsProvider);
    final all = ref.watch(mySubmissionsProvider).asData?.value ?? const [];
    final submissions = all
        .where(
          (s) =>
              s.status == FactSubmissionStatus.pending ||
              !dismissed.contains(s.id),
        )
        .toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 32),
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
                'YOUR FACTS',
                style: textTheme.headline.copyWith(
                  fontSize: 26,
                  color: colors.paperText,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: submissions.isEmpty
                    ? Center(
                        child: Text(
                          "you haven't submitted a fact yet.",
                          style: textTheme.label.copyWith(
                            color: colors.mutedText,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: submissions.length,
                        separatorBuilder: (context, i) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) =>
                            _SubmissionCard(submission: submissions[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmissionCard extends ConsumerWidget {
  final ActuallyFactSubmission submission;

  const _SubmissionCard({required this.submission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;

    final (badge, badgeColor) = switch (submission.status) {
      FactSubmissionStatus.approved => ('🎉 ADDED TO THE GAME', colors.accent),
      FactSubmissionStatus.rejected => ("DIDN'T MAKE IT", colors.faintText),
      FactSubmissionStatus.pending => ('PENDING VOTE', colors.paperText),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.paperBg,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  badge,
                  style: textTheme.caption.copyWith(color: badgeColor),
                ),
              ),
              if (submission.status != FactSubmissionStatus.pending)
                GestureDetector(
                  onTap: () => ref
                      .read(actuallyFactSubmissionActionsProvider)
                      .dismissResolved(submission.id),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colors.faintText,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            submission.statement,
            style: textTheme.body.copyWith(
              fontSize: 15,
              color: colors.paperText,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.check_rounded, size: 15, color: colors.accent),
              const SizedBox(width: 4),
              Text(
                '${submission.agreeCount} agreed',
                style: textTheme.caption.copyWith(color: colors.mutedText),
              ),
              const SizedBox(width: 16),
              Icon(Icons.close_rounded, size: 15, color: colors.danger),
              const SizedBox(width: 4),
              Text(
                '${submission.disagreeCount} disagreed',
                style: textTheme.caption.copyWith(color: colors.mutedText),
              ),
            ],
          ),
          if (submission.status == FactSubmissionStatus.pending) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(
                height: 8,
                color: colors.border,
                alignment: Alignment.centerLeft,
                child: LayoutBuilder(
                  builder: (context, constraints) => Container(
                    width:
                        constraints.maxWidth *
                        (submission.agreeCount /
                                ActuallyFactSubmission.voteThreshold)
                            .clamp(0, 1),
                    color: colors.accent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
