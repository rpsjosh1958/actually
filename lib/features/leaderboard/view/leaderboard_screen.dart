import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/accent_button.dart';
import '../../../core/widgets/navii_avatar_view.dart';
import '../view_model/leaderboard_view_model.dart';

class LeaderboardScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const LeaderboardScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;
    final pageAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  const SizedBox(width: 12),
                  Text(
                    'GLOBAL STREAKS',
                    style: textTheme.headline.copyWith(
                      fontSize: 24,
                      color: colors.paperText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Expanded(
                child: pageAsync.when(
                  data: (page) => ListView.separated(
                    itemCount: page.entries.length + (page.hasMore ? 1 : 0),
                    separatorBuilder: (context, i) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      if (i == page.entries.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: AccentButton(
                              label: 'LOAD MORE',
                              variant: AccentButtonVariant.outline,
                              isLoading: page.isLoadingMore,
                              onTap: page.isLoadingMore
                                  ? null
                                  : () => ref
                                        .read(leaderboardProvider.notifier)
                                        .loadMore(),
                            ),
                          ),
                        );
                      }
                      final r = page.entries[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: r.isCurrentUser
                              ? colors.accent
                              : colors.paperBg,
                          border: r.isCurrentUser
                              ? null
                              : Border.all(color: colors.border),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: r.isCurrentUser
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.14),
                                    blurRadius: 22,
                                    offset: const Offset(0, 10),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 30,
                              child: Text(
                                r.rank.toString().padLeft(2, '0'),
                                style: textTheme.label.copyWith(
                                  fontSize: 15,
                                  color: colors.faintText,
                                ),
                              ),
                            ),
                            NaviiAvatarView(seed: r.avatarSeed, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                r.displayName,
                                style: textTheme.label.copyWith(
                                  fontSize: 15,
                                  color: colors.paperText,
                                ),
                              ),
                            ),
                            Text(
                              '${r.score}',
                              style: textTheme.headline.copyWith(
                                fontSize: 20,
                                color: colors.paperText,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      'Could not load the leaderboard.',
                      style: textTheme.bodyRegular.copyWith(
                        color: colors.mutedText,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
