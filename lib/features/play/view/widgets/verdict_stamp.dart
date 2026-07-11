import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// The rotated CAP/BASED stamp that fades in as the player drags, mirroring
/// the prototype's opacity = min(1, abs(dx)/80) rule.
class VerdictStamp extends StatelessWidget {
  final String label;
  final double opacity;
  final double angleDegrees;
  final Color background;
  final Color foreground;

  const VerdictStamp({
    super.key,
    required this.label,
    required this.opacity,
    required this.angleDegrees,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).appTextTheme;
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: angleDegrees * 3.14159265 / 180,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            label,
            style: textTheme.headline.copyWith(
              fontSize: 26,
              color: foreground,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
