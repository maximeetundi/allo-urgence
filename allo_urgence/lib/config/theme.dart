import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlloUrgenceTheme {
  // Priority colors — Quebec triage scale
  static const Color priority1 = Color(0xFFDC2626); // Réanimation
  static const Color priority2 = Color(0xFFEA580C); // Très urgent
  static const Color priority3 = Color(0xFFF59E0B); // Urgent
  static const Color priority4 = Color(0xFF3B82F6); // Moins urgent
  static const Color priority5 = Color(0xFF16A34A); // Non urgent

  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color accent = Color(0xFF06B6D4);
  static const Color background = Color(0xFFF0F4FF);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);

  static Color getPriorityColor(int level) {
    switch (level) {
      case 1: return priority1;
      case 2: return priority2;
      case 3: return priority3;
      case 4: return priority4;
      case 5: return priority5;
      default: return priority4;
    }
  }

  static String getPriorityLabel(int level) {
    switch (level) {
      case 1: return 'Réanimation';
      case 2: return 'Très urgent';
      case 3: return 'Urgent';
      case 4: return 'Moins urgent';
      case 5: return 'Non urgent';
      default: return 'Inconnu';
    }
  }

  static IconData getPriorityIcon(int level) {
    switch (level) {
      case 1: return Icons.emergency;
      case 2: return Icons.warning_amber;
      case 3: return Icons.priority_high;
      case 4: return Icons.info_outline;
      case 5: return Icons.check_circle_outline;
      default: return Icons.help_outline;
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        secondary: accent,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
          elevation: 2,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        primary: primaryLight,
        secondary: accent,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
