import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/actually_profile_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/accent_button.dart';
import '../../play/view_model/play_view_model.dart';

class GameOverScreen extends ConsumerWidget {
  final VoidCallback onRunItBack;
  final VoidCallback onMenu;

  const GameOverScreen({
    super.key,
    required this.onRunItBack,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;
    final state = ref.watch(playViewModelProvider);
    final vm = ref.read(playViewModelProvider.notifier);
    final fact = state.currentFact;
    final best =
        ref.watch(actuallyProfileProvider).asData?.value?.bestStreak ??
        state.streak;

    final verdictWord = fact == null ? '' : (fact.isTrue ? 'BASED.' : 'CAP.');
    final verdictColor = fact != null && fact.isTrue
        ? colors.accent
        : colors.paperText;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COOKED.',
                style: textTheme.wordmark.copyWith(
                  fontSize: 56,
                  color: colors.paperText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'the streak is over, gang.',
                style: textTheme.label.copyWith(color: colors.mutedText),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      background: colors.accent,
                      label: 'FINAL STREAK',
                      labelColor: colors.paperText,
                      value: '${state.streak}',
                      valueColor: colors.paperText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      background: colors.paperBg,
                      border: colors.border,
                      label: 'PERSONAL BEST',
                      labelColor: colors.faintText,
                      value: '$best',
                      valueColor: colors.paperText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (fact != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: colors.paperBg,
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WHAT GOT YOU',
                        style: textTheme.caption.copyWith(
                          color: colors.faintText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fact.statement,
                        style: textTheme.body.copyWith(
                          fontSize: 16,
                          color: colors.paperText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          style: textTheme.bodyRegular.copyWith(
                            fontSize: 13,
                            color: colors.mutedText,
                          ),
                          children: [
                            TextSpan(
                              text: '$verdictWord ',
                              style: TextStyle(
                                color: verdictColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: '— ${fact.why}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      "streak synced to the global leaderboard",
                      style: textTheme.bodyRegular.copyWith(
                        fontSize: 12.5,
                        color: colors.mutedText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: AccentButton(
                      label: 'RUN IT BACK',
                      variant: AccentButtonVariant.ink,
                      fontSize: 13,
                      onTap: () {
                        vm.startSolo();
                        onRunItBack();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AccentButton(
                      label: 'MENU',
                      variant: AccentButtonVariant.outline,
                      fontSize: 13,
                      onTap: onMenu,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final Color background;
  final Color? border;
  final String label;
  final Color labelColor;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.background,
    this.border,
    required this.label,
    required this.labelColor,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).appTextTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        border: border != null ? Border.all(color: border!) : null,
        borderRadius: BorderRadius.circular(18),
        boxShadow: border == null
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.caption.copyWith(color: labelColor)),
          Text(value, style: textTheme.statNumber.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}
