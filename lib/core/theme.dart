import 'package:flutter/material.dart';

class SirexeTheme {
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceElevated = Color(0xFF21262D);
  static const Color accent = Color(0xFF238636);
  static const Color accentBlue = Color(0xFF1F6FEB);
  static const Color warning = Color(0xFFD29922);
  static const Color danger = Color(0xFFF85149);
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color border = Color(0xFF30363D);

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: accentBlue,
      secondary: accent,
      surface: surface,
      error: danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
    ),
  );
}
