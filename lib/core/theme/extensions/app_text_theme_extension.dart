import 'package:flutter/material.dart';

@immutable
class AppTextThemeExtension extends ThemeExtension<AppTextThemeExtension> {
  final TextStyle wordmark;
  final TextStyle headline;
  final TextStyle verdict;
  final TextStyle statNumber;
  final TextStyle button;
  final TextStyle body;
  final TextStyle bodyRegular;
  final TextStyle caption;
  final TextStyle label;

  const AppTextThemeExtension({
    required this.wordmark,
    required this.headline,
    required this.verdict,
    required this.statNumber,
    required this.button,
    required this.body,
    required this.bodyRegular,
    required this.caption,
    required this.label,
  });

  @override
  AppTextThemeExtension copyWith({
    TextStyle? wordmark,
    TextStyle? headline,
    TextStyle? verdict,
    TextStyle? statNumber,
    TextStyle? button,
    TextStyle? body,
    TextStyle? bodyRegular,
    TextStyle? caption,
    TextStyle? label,
  }) {
    return AppTextThemeExtension(
      wordmark: wordmark ?? this.wordmark,
      headline: headline ?? this.headline,
      verdict: verdict ?? this.verdict,
      statNumber: statNumber ?? this.statNumber,
      button: button ?? this.button,
      body: body ?? this.body,
      bodyRegular: bodyRegular ?? this.bodyRegular,
      caption: caption ?? this.caption,
      label: label ?? this.label,
    );
  }

  @override
  AppTextThemeExtension lerp(
    ThemeExtension<AppTextThemeExtension>? other,
    double t,
  ) {
    if (other is! AppTextThemeExtension) return this;
    return t < 0.5 ? this : other;
  }
}
