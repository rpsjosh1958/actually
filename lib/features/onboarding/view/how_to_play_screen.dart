import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'onboarding_screen.dart';

/// On-demand reference screen, opened from the profile menu — reuses the
/// same "how to play" and "stakes" content shown during onboarding, just
/// stacked on one scrollable page instead of a forced step-by-step flow.
class HowToPlayScreen extends StatelessWidget {
  final VoidCallback onBack;

  const HowToPlayScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).appTextTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 14, 26, 32),
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
              const SizedBox(height: 20),
              StepHowToPlay(colors: colors, textTheme: textTheme),
              const SizedBox(height: 34),
              StepStakes(colors: colors, textTheme: textTheme),
            ],
          ),
        ),
      ),
    );
  }
}
