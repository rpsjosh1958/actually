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
}

extension AppThemeExtension on ThemeData {
  AppColorsExtension get appColors => extension<AppColorsExtension>()!;
  AppTextThemeExtension get appTextTheme => extension<AppTextThemeExtension>()!;
}
