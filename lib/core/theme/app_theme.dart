import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_palette.dart';
import 'app_typography.dart';
export 'extensions/app_colors_extension.dart';
export 'extensions/app_text_theme_extension.dart';
import 'extensions/app_colors_extension.dart';
import 'extensions/app_text_theme_extension.dart';

class AppThemeNotifier {
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppPalette.background,
    // Properly loads/registers Space Grotesk as the default for every
    // widget that doesn't use one of AppTypography's explicit styles below
    // (e.g. default AppBar/SnackBar text) — a bare `fontFamily: 'Space
    // Grotesk'` string doesn't guarantee the font is actually loaded.
    textTheme: GoogleFonts.spaceGroteskTextTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.accentDefault,
      brightness: Brightness.light,
    ),
    extensions: [
      const AppColorsExtension(
        background: AppPalette.background,
        paperBg: AppPalette.paperBg,
        paperText: AppPalette.paperText,
        inkBg: AppPalette.inkBg,
        inkText: AppPalette.inkText,
        accent: AppPalette.accentDefault,
        border: AppPalette.border,
        mutedText: AppPalette.mutedText,
        faintText: AppPalette.faintText,
        danger: AppPalette.danger,
      ),
      AppTextThemeExtension(
        wordmark: AppTypography.wordmark,
        headline: AppTypography.headline,
        verdict: AppTypography.verdict,
        statNumber: AppTypography.statNumber,
        button: AppTypography.button,
        body: AppTypography.body,
        bodyRegular: AppTypography.bodyRegular,
        caption: AppTypography.caption,
        label: AppTypography.label,
      ),
    ],
  );

  /// Same app, re-skinned for Disney night — every screen reads colours and
  /// type from these extensions, so wrapping a subtree in this theme is all
  /// it takes. Storybook display face (Cinzel Decorative) + rounded body
  /// (Fredoka).
  static final ThemeData disney = light.copyWith(
    scaffoldBackgroundColor: AppPalette.disneyBackground,
    textTheme: GoogleFonts.fredokaTextTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.disneyInkBg,
      brightness: Brightness.light,
    ),
    extensions: [
      const AppColorsExtension(
        background: AppPalette.disneyBackground,
        paperBg: AppPalette.paperBg,
        paperText: AppPalette.disneyPaperText,
        inkBg: AppPalette.disneyInkBg,
        inkText: AppPalette.inkText,
        accent: AppPalette.disneyAccent,
        border: AppPalette.disneyBorder,
        mutedText: AppPalette.disneyMutedText,
        faintText: AppPalette.disneyFaintText,
        danger: AppPalette.danger,
      ),
      AppTextThemeExtension(
        wordmark: _storybook(AppTypography.wordmark),
        headline: _storybook(AppTypography.headline),
        verdict: _storybook(AppTypography.verdict),
        statNumber: _rounded(AppTypography.statNumber, FontWeight.w700),
        button: _rounded(AppTypography.button, FontWeight.w700),
        body: _rounded(AppTypography.body, FontWeight.w600),
        bodyRegular: _rounded(AppTypography.bodyRegular, FontWeight.w400),
        caption: _rounded(AppTypography.caption, FontWeight.w700),
        label: _rounded(AppTypography.label, FontWeight.w700),
      ),
    ],
  );

  static TextStyle _storybook(TextStyle base) =>
      GoogleFonts.cinzelDecorative(textStyle: base, fontWeight: FontWeight.w900);

  static TextStyle _rounded(TextStyle base, FontWeight weight) =>
      GoogleFonts.fredoka(textStyle: base, fontWeight: weight);
}

extension AppThemeExtension on ThemeData {
  AppColorsExtension get appColors => extension<AppColorsExtension>()!;
  AppTextThemeExtension get appTextTheme => extension<AppTextThemeExtension>()!;
}
