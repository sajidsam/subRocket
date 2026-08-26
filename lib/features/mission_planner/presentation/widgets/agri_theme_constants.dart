import 'package:flutter/material.dart';

/// Styling constants accurately matching the AG.Drone Agricultural Survey theme
class AgriColors {
  // Dark slate and charcoal foundations
  static const Color background = Color(0xFF141518);
  static const Color cardBackground = Color(0xFF1E1F24);
  static const Color cardElevated = Color(0xFF26282F);
  static const Color headerBackground = Color(0xFF1A1B20);
  static const Color inputBackground = Color(0xFF18191D);
  static const Color stepperBackground = Color(0xFF1C1D22);
  
  // Borders
  static const Color border = Color(0xFF2E313A);
  static const Color borderLight = Color(0xFF3D414D);
  static const Color borderSubtle = Color(0xFF25272F);
  
  // Vibrant Agricultural Orange Primary Accents
  static const Color orangePrimary = Color(0xFFFF6B00);
  static const Color orangeDark = Color(0xFFE05A00);
  static const Color orangeLight = Color(0xFFFF8533);
  static const Color orangeSubtle = Color(0x26FF6B00);
  static const Color orangeGlow = Color(0x40FF6B00);

  // Status & Telemetry
  static const Color greenActive = Color(0xFF2BD97C);
  static const Color greenSubtle = Color(0x262BD97C);
  static const Color yellowAmber = Color(0xFFF5A623);
  static const Color redAlert = Color(0xFFFF4D4F);
  static const Color cyanAccent = Color(0xFF00D2FF);

  // Text
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFE6E8EC);
  static const Color textSecondary = Color(0xFF9094A0);
  static const Color textMuted = Color(0xFF656976);
  static const Color textDark = Color(0xFF111215);
}

class AgriDecorations {
  static BoxDecoration cardBox({
    Color color = AgriColors.cardBackground,
    double radius = 10,
    Color borderColor = AgriColors.border,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
    );
  }

  static BoxDecoration orangeButtonBox({double radius = 8}) {
    return BoxDecoration(
      color: AgriColors.orangePrimary,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(
          color: AgriColors.orangeGlow,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }
}
