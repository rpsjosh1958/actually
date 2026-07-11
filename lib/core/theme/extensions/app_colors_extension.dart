import 'package:flutter/material.dart';

@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color paperBg;
  final Color paperText;
  final Color inkBg;
  final Color inkText;
  final Color accent;
  final Color border;
  final Color mutedText;
  final Color faintText;
  final Color danger;

  const AppColorsExtension({
    required this.background,
    required this.paperBg,
    required this.paperText,
    required this.inkBg,
    required this.inkText,
    required this.accent,
    required this.border,
    required this.mutedText,
    required this.faintText,
    required this.danger,
  });

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? paperBg,
    Color? paperText,
    Color? inkBg,
    Color? inkText,
    Color? accent,
    Color? border,
    Color? mutedText,
    Color? faintText,
    Color? danger,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      paperBg: paperBg ?? this.paperBg,
      paperText: paperText ?? this.paperText,
      inkBg: inkBg ?? this.inkBg,
      inkText: inkText ?? this.inkText,
      accent: accent ?? this.accent,
      border: border ?? this.border,
      mutedText: mutedText ?? this.mutedText,
      faintText: faintText ?? this.faintText,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      paperBg: Color.lerp(paperBg, other.paperBg, t)!,
      paperText: Color.lerp(paperText, other.paperText, t)!,
      inkBg: Color.lerp(inkBg, other.inkBg, t)!,
      inkText: Color.lerp(inkText, other.inkText, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      border: Color.lerp(border, other.border, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      faintText: Color.lerp(faintText, other.faintText, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}
