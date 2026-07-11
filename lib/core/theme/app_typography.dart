import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Archivo Black for chunky display type, Space Grotesk for everything else.
class AppTypography {
  static TextStyle get wordmark =>
      GoogleFonts.archivoBlack(fontSize: 52, height: 0.95, letterSpacing: -0.5);

  static TextStyle get headline =>
      GoogleFonts.archivoBlack(fontSize: 30, height: 1.05);

  static TextStyle get verdict =>
      GoogleFonts.archivoBlack(fontSize: 46, letterSpacing: 0.2);

  static TextStyle get statNumber =>
      GoogleFonts.archivoBlack(fontSize: 40, height: 1.1);

  static TextStyle get button =>
      GoogleFonts.archivoBlack(fontSize: 15, letterSpacing: 0.7);

  static TextStyle get body => GoogleFonts.spaceGrotesk(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  static TextStyle get bodyRegular => GoogleFonts.spaceGrotesk(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static TextStyle get caption => GoogleFonts.spaceGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  static TextStyle get label =>
      GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700);

  /// Fact-statement size is data-dependent (prototype's 30/26/23px length rule),
  /// so it's a function, not a fixed token — see PlayCardMetrics.fontSizeFor.
  static TextStyle factBody(double fontSize) => GoogleFonts.spaceGrotesk(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    height: 1.18,
    letterSpacing: -0.2,
  );
}
