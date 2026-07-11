import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/actually_fact_submission.dart';
import '../../../core/providers/actually_fact_submission_provider.dart';
import '../../../core/providers/actually_profile_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/navii_avatar_view.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../factvote/view/my_submissions_screen.dart';
import '../../factvote/view/submit_fact_screen.dart';
import '../../factvote/view/vote_queue_screen.dart';
import '../../onboarding/view/how_to_play_screen.dart';

class MenuScreen extends ConsumerWidget {
  final VoidCallback onStartSolo;
  final VoidCallback onVersus;
  final VoidCallback onLeaderboard;

  const MenuScreen({
    super.key,
    required this.onStartSolo,
    required this.onVersus,
    required this.onLeaderboard,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;
    final profile = ref.watch(userProfileProvider).asData?.value;
    final best =
        ref.watch(actuallyProfileProvider).asData?.value?.bestStreak ?? 0;

    final pendingVoteCount =
        ref.watch(pendingVotesForMeProvider).asData?.value.length ?? 0;
    final dismissedResolved = ref.watch(dismissedResolvedSubmissionsProvider);
    final hasResolvedUpdate =
        (ref.watch(mySubmissionsProvider).asData?.value ?? const []).any(
          (s) =>
              s.status != FactSubmissionStatus.pending &&
              !dismissedResolved.contains(s.id),
        );

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 30),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<void>(
                    padding: EdgeInsets.zero,
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: colors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => HowToPlayScreen(
                              onBack: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.help_outline_rounded,
                              size: 18,
                              color: colors.paperText,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'How to play',
                              style: textTheme.label.copyWith(
                                color: colors.paperText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SubmitFactScreen(
                              onBack: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                              color: colors.paperText,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Submit a fact',
                              style: textTheme.label.copyWith(
                                color: colors.paperText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MySubmissionsScreen(
                              onBack: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fact_check_outlined,
                              size: 18,
                              color: colors.paperText,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'My fact submissions',
                              style: textTheme.label.copyWith(
                                color: colors.paperText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap: () =>
                            ref.read(authViewModelProvider.notifier).signOut(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              size: 18,
                              color: colors.paperText,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Sign out',
                              style: textTheme.label.copyWith(
                                color: colors.paperText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: NaviiAvatarView(
                      seed: profile?.avatarSeed ?? '',
                      size: 34,
                    ),
                  ),
                ],
              ),
              if (pendingVoteCount > 0)
                _FactBanner(
                  text: pendingVoteCount == 1
                      ? '1 new fact needs your vote'
                      : '$pendingVoteCount new facts need your vote',
                  colors: colors,
                  textTheme: textTheme,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => VoteQueueScreen(
                        onBack: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              if (hasResolvedUpdate)
                _FactBanner(
                  text: 'one of your submitted facts has an update',
                  colors: colors,
                  textTheme: textTheme,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MySubmissionsScreen(
                        onBack: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: textTheme.wordmark.copyWith(
                          color: colors.paperText,
                          fontSize: 46,
                        ),
                        children: [
                          const TextSpan(text: 'ACTUALLY'),
                          TextSpan(
                            text: '...',
                            style: TextStyle(color: colors.accent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'myth-buster swipe game',
                      style: textTheme.label.copyWith(color: colors.mutedText),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.paperBg,
                        border: Border.all(color: colors.border),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
                            'PB STREAK  $best',
                            style: textTheme.label.copyWith(
                              color: colors.paperText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _MenuCard(
                    onTap: onStartSolo,
                    background: colors.accent,
                    title: 'SOLO STREAK',
                    subtitle: 'survive as long as you can',
                    titleColor: colors.paperText,
                    subtitleColor: colors.paperText.withValues(alpha: 0.55),
                    trailing: Text(
                      '→',
                      style: textTheme.headline.copyWith(
                        fontSize: 26,
                        color: colors.paperText,
                      ),
                    ),
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: 12),
                  _MenuCard(
                    onTap: onVersus,
                    background: colors.inkBg,
                    title: 'VERSUS',
                    subtitle: 'swipe head-to-head, live',
                    titleColor: colors.inkText,
                    subtitleColor: Colors.white70,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BlinkingDot(color: colors.accent),
                        const SizedBox(width: 8),
                        Text(
                          'LIVE',
                          style: textTheme.caption.copyWith(
                            color: colors.accent,
                          ),
                        ),
                      ],
                    ),
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: onLeaderboard,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: colors.paperBg,
                        border: Border.all(color: colors.border),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LEADERBOARD',
                            style: textTheme.headline.copyWith(
                              fontSize: 17,
                              color: colors.paperText,
                            ),
                          ),
                          Text(
                            'global streaks',
                            style: textTheme.label.copyWith(
                              fontSize: 13,
                              color: colors.faintText,
                            ),
                          ),
                        ],
                      ),
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

class _MenuCard extends StatelessWidget {
  final VoidCallback onTap;
  final Color background;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;
  final Widget trailing;
  final AppTextThemeExtension textTheme;

  const _MenuCard({
    required this.onTap,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
    required this.trailing,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.headline.copyWith(
                    fontSize: 22,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.label.copyWith(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  final Color color;
  const _BlinkingDot({required this.color});

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.25).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class _FactBanner extends StatelessWidget {
  final String text;
  final AppColorsExtension colors;
  final AppTextThemeExtension textTheme;
  final VoidCallback onTap;

  const _FactBanner({
    required this.text,
    required this.colors,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: textTheme.label.copyWith(
                    fontSize: 13,
                    color: colors.paperText,
                  ),
                ),
              ),
              Text(
                '→',
                style: textTheme.label.copyWith(color: colors.paperText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
