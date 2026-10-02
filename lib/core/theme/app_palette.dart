import 'package:flutter/material.dart';

/// Actually's own visual identity — unrelated to SORTA's neo-brutalist palette.
class AppPalette {
  static const background = Color(0xFFF1EFE9);
  static const paperBg = Colors.white;
  static const paperText = Colors.black;
  static const inkBg = Colors.black;
  static const inkText = Colors.white;
  static const border = Color(0xFFE2DFD8);
  static const mutedText = Color(0xFF777777);
  static const faintText = Color(0xFF999999);

  static const accentDefault = Color(0xFF00E5A0);
  static const accentPresets = <Color>[
    Color(0xFF00E5A0),
    Color(0xFFFF3B30),
    Color(0xFFCCFF00),
    Color(0xFFFF9500),
  ];

  static const danger = Color(0xFFFF3B30);

  // Disney night — a light storybook palette (navy, royal blue, gold). Kept
  // light on purpose: paperText doubles as text-on-background, so a dark
  // background would hide every header.
  static const disneyBackground = Color(0xFFF1EDFB);
  static const disneyPaperText = Color(0xFF141B4D);
  static const disneyInkBg = Color(0xFF23308C);
  static const disneyAccent = Color(0xFFF4BE3C);
  static const disneyBorder = Color(0xFFDCD6EF);
  static const disneyMutedText = Color(0xFF5E6390);
  static const disneyFaintText = Color(0xFF8F93B8);
}
