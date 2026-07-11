import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/actually_fact_submission_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/accent_button.dart';

/// One pending community fact at a time — AGREE if it holds up, DISAGREE if
/// not. Advances through every submission the player hasn't voted on yet.
class VoteQueueScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const VoteQueueScreen({super.key, required this.onBack});

  @override
  ConsumerState<VoteQueueScreen> createState() => _VoteQueueScreenState();
}

class _VoteQueueScreenState extends ConsumerState<VoteQueueScreen> {
  // Hides an item the instant its own vote is cast, without waiting on the
  // round trip through the Cloud Function that updates voterUids server-side.
  final _justVoted = <String>{};

  void _vote(String submissionId, bool agree) {
    setState(() => _justVoted.add(submissionId));
    ref.read(actuallyFactSubmissionActionsProvider).vote(submissionId, agree);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;
    final allPending =
        ref.watch(pendingVotesForMeProvider).asData?.value ?? const [];
    final queue = allPending.where((s) => !_justVoted.contains(s.id)).toList();

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
                child: queue.isEmpty
                    ? Center(
                        child: Text(
                          "you're all caught up.\nno facts waiting on your vote.",
                          textAlign: TextAlign.center,
                          style: textTheme.label.copyWith(
                            color: colors.mutedText,
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${queue.length} to review',
                            style: textTheme.caption.copyWith(
                              color: colors.faintText,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: colors.paperBg,
                              border: Border.all(color: colors.border),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'submitted by ${queue.first.submitterName}',
                                  style: textTheme.caption.copyWith(
                                    color: colors.faintText,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  queue.first.statement,
                                  style: textTheme.body.copyWith(
                                    fontSize: 18,
                                    color: colors.paperText,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  queue.first.why,
                                  style: textTheme.bodyRegular.copyWith(
                                    color: colors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: AccentButton(
                                  label: 'DISAGREE',
                                  variant: AccentButtonVariant.outline,
                                  onTap: () => _vote(queue.first.id, false),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AccentButton(
                                  label: 'AGREE',
                                  variant: AccentButtonVariant.accent,
                                  onTap: () => _vote(queue.first.id, true),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
