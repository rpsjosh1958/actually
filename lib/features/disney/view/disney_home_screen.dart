import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/providers/actually_profile_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/accent_button.dart';

/// Landing page for Disney night — shown inside the Disney theme (see
/// app_shell.dart), so every colour/font here is already re-skinned.
class DisneyHomeScreen extends ConsumerWidget {
  final VoidCallback onPlay;
  final VoidCallback onLeaderboard;
  final VoidCallback onBack;

  const DisneyHomeScreen({
    super.key,
    required this.onPlay,
    required this.onLeaderboard,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;
    final best =
        ref.watch(actuallyProfileProvider).asData?.value?.disneyBestStreak ??
        0;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onBack,
                  child: Text(
                    '←',
                    style: textTheme.headline.copyWith(
                      fontSize: 22,
                      color: colors.paperText,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '✨ DISNEY NIGHT',
                      style: textTheme.caption.copyWith(color: colors.mutedText),
                    ),
                    const SizedBox(height: 10),
                    // Tinted in code: the SVG itself has no colour we rely on.
                    SvgPicture.asset(
                      'assets/Disney_wordmark.svg',
                      height: 84,
                      colorFilter: ColorFilter.mode(
                        colors.paperText,
                        BlendMode.srcIn,
                      ),
                    ),
                    Text(
                      'TRIVIA',
                      style: textTheme.wordmark.copyWith(
                        fontSize: 40,
                        color: colors.paperText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'simple disney facts. swipe right if it\'s true, left if it\'s false.',
                      style: textTheme.bodyRegular.copyWith(
                        color: colors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 18),
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
                      child: Text(
                        'DISNEY PB  $best',
                        style: textTheme.label.copyWith(color: colors.paperText),
                      ),
                    ),
                  ],
                ),
              ),
              AccentButton(
                label: 'PLAY',
                variant: AccentButtonVariant.accent,
                onTap: onPlay,
              ),
              const SizedBox(height: 12),
              AccentButton(
                label: 'DISNEY LEADERBOARD',
                variant: AccentButtonVariant.outline,
                onTap: onLeaderboard,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
