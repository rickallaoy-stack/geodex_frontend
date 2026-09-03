import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 🎨 UI GEODEX — Système de surfaces et thème dark militaire/industriel

class SirexeTheme {
  // ─── Surfaces (3 niveaux) ────────────────────────────────────────────────
  static const Color surfaceLevel0 = Color(0xFF0A0A14); // fond global
  static const Color surfaceLevel1 = Color(0xFF12121F); // cartes, sidebar
  static const Color surfaceLevel2 = Color(0xFF1A1A2E); // popups, survols

  // Alias rétro-compatibilité
  static const Color background    = surfaceLevel0;
  static const Color surface1      = surfaceLevel1;
  static const Color surface2      = surfaceLevel2;
  static const Color surface       = surfaceLevel1;
  static const Color surfaceElevated = surfaceLevel2;

  // ─── Bordures ────────────────────────────────────────────────────────────
  static const Color border = Color(0xFF30363D);
  static const Color borderSubtle = Color(0xFF21262D);

  // ─── Accents (palette géologique / militaire) ────────────────────────────
  static const Color primary = Color(0xFF2E9166); // vert opérationnel
  static const Color secondary = Color(0xFFB86B2E); // terre / ocres
  static const Color accentBlue = Color(0xFF1F6FEB); // info / tech
  static const Color accent = secondary; // alias historique

  // ─── Statuts ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E9166);
  static const Color warning = Color(0xFFD29922);
  static const Color danger = Color(0xFFF85149);

  // ─── Texte ───────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);

  // ─── Ressources minières ─────────────────────────────────────────────────
  static const Color resourceGold = Color(0xFFD4A843);
  static const Color resourceNickel = Color(0xFF7BBFDE);
  static const Color resourceManganese = Color(0xFFB87AE0);
  static const Color resourceOil = Color(0xFF5BBBAD);

  // ─── Typographie ─────────────────────────────────────────────────────────
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        color: textPrimary,
        fontSize: 12,
      );

  static TextStyle get monoSmall => GoogleFonts.jetBrainsMono(
        color: textSecondary,
        fontSize: 10,
        letterSpacing: 0.5,
      );

  static TextStyle get monoLabel => GoogleFonts.jetBrainsMono(
        color: textSecondary,
        fontSize: 9,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get body => GoogleFonts.inter(
        color: textPrimary,
        fontSize: 13,
      );

  static TextStyle get bodySecondary => GoogleFonts.inter(
        color: textSecondary,
        fontSize: 12,
      );

  // ─── ThemeData dark ──────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: surfaceLevel0,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: surfaceLevel1,
          error: danger,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: surfaceLevel1,
          foregroundColor: textPrimary,
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceLevel1,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(
              color: Color(0xFF30363D),
              width: 0.5,
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: surfaceLevel2,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Color(0xFF30363D),
              width: 0.5,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceLevel1,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF30363D)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF30363D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accentBlue, width: 1.5),
          ),
          labelStyle: GoogleFonts.inter(
            color: textSecondary,
            fontSize: 11,
          ),
          hintStyle: GoogleFonts.inter(
            color: textSecondary,
            fontSize: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            side: const BorderSide(color: Color(0xFF30363D)),
            textStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.inter(color: textPrimary),
          bodyMedium: GoogleFonts.inter(color: textPrimary),
          bodySmall: GoogleFonts.inter(color: textPrimary),
          displayLarge: GoogleFonts.inter(color: textPrimary),
          displayMedium: GoogleFonts.inter(color: textPrimary),
          displaySmall: GoogleFonts.inter(color: textPrimary),
          headlineLarge: GoogleFonts.inter(color: textPrimary),
          headlineMedium: GoogleFonts.inter(color: textPrimary),
          headlineSmall: GoogleFonts.inter(color: textPrimary),
          titleLarge: GoogleFonts.inter(color: textPrimary),
          titleMedium: GoogleFonts.inter(color: textPrimary),
          titleSmall: GoogleFonts.inter(color: textPrimary),
          labelLarge: GoogleFonts.inter(color: textPrimary),
          labelMedium: GoogleFonts.inter(color: textPrimary),
          labelSmall: GoogleFonts.inter(color: textPrimary),
        ),
      );
}
