import 'package:flutter/material.dart';

class GcsColors {
  // Ultra-Dark Obsidian Foundation
  static const Color background = Color(0xFF0D0F12);
  static const Color frameBackground = Color(0xFF07090C);
  static const Color cardBackground = Color(0xFF14171D);
  static const Color cardSurface = Color(0xFF181C23);
  static const Color cardSurfaceLight = Color(0xFF222731);
  static const Color surfaceDark = Color(0xFF11141A);
  static const Color surfaceCard = Color(0xFF181C23);
  static const Color border = Color(0xFF252A36);
  static const Color borderLight = Color(0xFF363E4F);
  static const Color borderSubtle = Color(0xFF1E232D);

  // Reference Color Grading Accents
  static const Color goldAccent = Color(0xFFF5B800);
  static const Color amberAccent = Color(0xFFF5B800);
  static const Color techAmber = Color(0xFFF5B800);
  static const Color aviationBlue = Color(0xFF2563EB);
  static const Color blueAccent = Color(0xFF3B82F6);
  static const Color cyanAccent = Color(0xFF38BDF8);
  static const Color skyBlue = Color(0xFF38BDF8);
  static const Color greenActive = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF97316);
  static const Color alertRed = Color(0xFFEF4444);
  static const Color groundBrown = Color(0xFF5D4037);

  // Multi-Channel RGBY Dot Indicators
  static const Color channelRed = Color(0xFFEF4444);
  static const Color channelGreen = Color(0xFF10B981);
  static const Color channelBlue = Color(0xFF3B82F6);
  static const Color channelYellow = Color(0xFFF59E0B);

  // HUD Text & Readouts
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDark = Color(0xFF334155);
}

class GcsTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GcsColors.background,
      primaryColor: GcsColors.aviationBlue,
      colorScheme: const ColorScheme.dark(
        primary: GcsColors.aviationBlue,
        secondary: GcsColors.goldAccent,
        surface: GcsColors.cardBackground,
        error: GcsColors.alertRed,
      ),
      fontFamily: 'sans-serif',
      cardTheme: CardThemeData(
        color: GcsColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: GcsColors.border, width: 1.0),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: GcsColors.background,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 1.5,
          color: GcsColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GcsColors.cardSurfaceLight,
          foregroundColor: GcsColors.textPrimary,
          elevation: 0,
          side: const BorderSide(color: GcsColors.borderLight, width: 1.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
