import 'package:flutter/material.dart';

class SirexeTheme {
  // Background / surfaces
  static const Color background = Color(0xFF07121A);
  static const Color surface = Color(0xFF0F1B24);
  static const Color surfaceElevated = Color(0xFF16262F);
  static const Color border = Color(0xFF22313A);

  // Primary accents (earthy / geology)
  static const Color primary = Color(0xFF2E9166); // verdoyant
  static const Color secondary = Color(0xFFB86B2E); // terre / ocres
  static const Color accentBlue = Color(0xFF1F6FEB);
  // Alias historique utilisé par l'app
  static const Color accent = secondary;

  // Status
  static const Color success = Color(0xFF38A169);
  static const Color warning = Color(0xFFF6AD55);
  static const Color danger = Color(0xFFEF4444);

  // Text
  static const Color textPrimary = Color(0xFFE7F0F3);
  static const Color textSecondary = Color(0xFF9AA6AF);

  // Resource colors
  static const Color resourceGold = Color(0xFFD4A843);
  static const Color resourceNickel = Color(0xFF7BBFDE);
  static const Color resourceManganese = Color(0xFFB87AE0);
  static const Color resourceOil = Color(0xFF5BBBAD);

  // Convenience ThemeData (dark)
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
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
