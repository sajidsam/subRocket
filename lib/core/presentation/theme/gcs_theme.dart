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
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GcsColors.frameBackground,
      primaryColor: GcsColors.aviationBlue,
      canvasColor: GcsColors.surfaceDark,
      cardColor: GcsColors.cardBackground,
      colorScheme: const ColorScheme.dark(
        primary: GcsColors.cyanAccent,
        secondary: GcsColors.goldAccent,
        surface: GcsColors.cardBackground,
        error: GcsColors.alertRed,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: GcsColors.textPrimary,
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
        backgroundColor: GcsColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: GcsColors.cyanAccent),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.5,
          fontFamily: 'monospace',
          color: GcsColors.textPrimary,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: GcsColors.cyanAccent,
        labelColor: GcsColors.cyanAccent,
        unselectedLabelColor: GcsColors.textSecondary,
        dividerColor: GcsColors.border,
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          fontFamily: 'monospace',
          letterSpacing: 1.0,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          letterSpacing: 0.8,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GcsColors.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: GcsColors.textMuted, fontSize: 12),
        labelStyle: const TextStyle(color: GcsColors.textSecondary, fontSize: 12, fontFamily: 'monospace'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GcsColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GcsColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GcsColors.cyanAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GcsColors.alertRed),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: GcsColors.cyanAccent,
        inactiveTrackColor: GcsColors.borderLight,
        thumbColor: GcsColors.goldAccent,
        overlayColor: Color(0x29F5B800),
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return GcsColors.cyanAccent;
          }
          return Colors.white54;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return GcsColors.aviationBlue.withValues(alpha: 0.5);
          }
          return GcsColors.cardSurfaceLight;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: GcsColors.surfaceCard,
        selectedColor: GcsColors.cyanAccent,
        labelStyle: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white),
        side: const BorderSide(color: GcsColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: GcsColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GcsColors.border, width: 1.5),
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
            fontFamily: 'monospace',
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: GcsColors.border,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }
}
