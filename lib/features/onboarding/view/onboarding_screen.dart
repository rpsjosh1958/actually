import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../view_model/onboarding_view_model.dart';

class OnboardingScreen extends ConsumerWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;
    final step = ref.watch(onboardingStepProvider);
    final vm = ref.read(onboardingStepProvider.notifier);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 14, 26, 30),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onComplete,
                  child: Text(
                    'SKIP',
                    style: textTheme.label.copyWith(
                      color: colors.faintText,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) => SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(step),
                    child: Center(
                      child: switch (step) {
                        0 => _StepIntro(colors: colors, textTheme: textTheme),
                        1 => StepHowToPlay(
                          colors: colors,
                          textTheme: textTheme,
                        ),
                        _ => StepStakes(colors: colors, textTheme: textTheme),
                      },
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(3, (i) {
                      final active = i == step;
                      return Container(
                        margin: const EdgeInsets.only(right: 7),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? colors.inkBg : colors.border,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (vm.next()) onComplete();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: colors.inkBg,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        step == 2 ? "LET'S GO" : 'NEXT',
                        style: textTheme.button.copyWith(color: colors.inkText),
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

class _StepIntro extends StatelessWidget {
  final AppColorsExtension colors;
  final AppTextThemeExtension textTheme;
  const _StepIntro({required this.colors, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 16),
        Text(
          'the myth-buster swipe game',
          style: textTheme.label.copyWith(color: colors.paperText),
        ),
        const SizedBox(height: 26),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            'half of what you believe is cap. one giant fact at a time — call it.',
            style: textTheme.bodyRegular.copyWith(color: colors.mutedText),
          ),
        ),
      ],
    );
  }
}

class StepHowToPlay extends StatelessWidget {
  final AppColorsExtension colors;
  final AppTextThemeExtension textTheme;
  const StepHowToPlay({
    super.key,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'HOW TO PLAY',
          style: textTheme.headline.copyWith(color: colors.paperText),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              '←',
              style: textTheme.headline.copyWith(
                fontSize: 34,
                color: colors.paperText,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colors.inkBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAP',
                      style: textTheme.headline.copyWith(
                        fontSize: 20,
                        color: colors.inkText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "swipe left if it's false",
                      style: textTheme.bodyRegular.copyWith(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BASED',
                      style: textTheme.headline.copyWith(
                        fontSize: 20,
                        color: colors.paperText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "swipe right if it's true",
                      style: textTheme.bodyRegular.copyWith(
                        fontSize: 13,
                        color: colors.paperText.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '→',
              style: textTheme.headline.copyWith(
                fontSize: 34,
                color: colors.paperText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'watch for logic traps. the obvious answer is usually the trap.',
          style: textTheme.bodyRegular.copyWith(color: colors.mutedText),
        ),
      ],
    );
  }
}

class StepStakes extends StatelessWidget {
  final AppColorsExtension colors;
  final AppTextThemeExtension textTheme;
  const StepStakes({super.key, required this.colors, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        '01',
        '10 seconds a card. one wrong swipe — or one hesitation — ends your streak.',
      ),
      ('02', 'versus mode — swipe head-to-head against a real player, live.'),
      (
        '03',
        "see your placements on the global leaderboard. it's a flex, but also a fact.",
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'THE STAKES',
          style: textTheme.headline.copyWith(color: colors.paperText),
        ),
        const SizedBox(height: 16),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$1,
                  style: textTheme.label.copyWith(
                    fontSize: 15,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.$2,
                    style: textTheme.bodyRegular.copyWith(
                      color: colors.paperText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
