import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette
  static const Color background = Color(0xFF080C14);
  static const Color surface = Color(0xFF0F1623);
  static const Color surfaceAlt = Color(0xFF141C2D);
  static const Color accent = Color(0xFF6366F1); // electric indigo
  static const Color accentLight = Color(0xFF818CF8);
  static const Color accentGlow = Color(0x336366F1);
  static const Color safe = Color(0xFF38BDF8);    // sky-blue  → No Risk
  static const Color success = Color(0xFF10B981); // emerald   → Low Risk
  static const Color warning = Color(0xFFF59E0B); // amber     → Medium Risk
  static const Color danger = Color(0xFFEF4444);  // red       → High Risk
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);
  static const Color border = Color(0xFF1E293B);
  static const Color glass = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF080C14), Color(0xFF0D1425), Color(0xFF080C14)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const LinearGradient confidenceGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
  );

  static ThemeData dark() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentLight,
        surface: surface,
        error: danger,
      ),
      textTheme: GoogleFonts.interTextTheme(
        base.textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // Glass card decoration
  static BoxDecoration glassCard({double radius = 20, Color? borderColor}) {
    return BoxDecoration(
      color: glass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? glassBorder, width: 1),
    );
  }
}
