import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AccentButtonVariant { accent, ink, outline }

/// The pill-shaped, Archivo-Black-labelled CTA used across menu, onboarding,
/// gameover, prematch and result — one widget so the shape/shadow/press
/// state stays consistent everywhere it appears.
class AccentButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AccentButtonVariant variant;
  final bool isLoading;
  final double? fontSize;

  const AccentButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = AccentButtonVariant.ink,
    this.isLoading = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final enabled = onTap != null && !isLoading;

    Color bg;
    Color fg;
    Border? border;
    switch (variant) {
      case AccentButtonVariant.accent:
        bg = colors.accent;
        fg = colors.paperText;
        border = null;
      case AccentButtonVariant.ink:
        bg = colors.inkBg;
        fg = colors.inkText;
        border = null;
      case AccentButtonVariant.outline:
        bg = colors.paperBg;
        fg = colors.paperText;
        border = Border.all(color: colors.border, width: 1);
    }

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: enabled || isLoading ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 30),
          decoration: BoxDecoration(
            color: bg,
            border: border,
            borderRadius: BorderRadius.circular(99),
          ),
          child: isLoading
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).appTextTheme.button.copyWith(color: fg, fontSize: fontSize),
                ),
        ),
      ),
    );
  }
}
