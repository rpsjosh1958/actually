import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bouncing_dots.dart';

/// Very brief splash — just the "..." from the ACTUALLY wordmark, bouncing
/// one dot at a time, in the accent green. Shown once on cold start before
/// the auth gate decides where to send the player.
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _duration = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    Future.delayed(_duration, () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(child: BouncingDots(color: colors.accent)),
    );
  }
}
