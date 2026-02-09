import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color bg = Color(0xFF0C0E14);
  static const Color card = Color(0xFF12141D);
  static const Color cardHover = Color(0xFF181B27);
  static const Color border = Color(0xFF1E2231);
  static const Color borderLight = Color(0x99181B25);
  static const Color text = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFFB0B5C5);
  static const Color textMuted = Color(0xFF7A8099);
  static const Color textDim = Color(0xFF4B5068);
  static const Color accent = Color(0xFF8B5CF6);
  static const Color accentHover = Color(0xFF7C3AED);
  static const Color sidebar = Color(0xFF0F1119);
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFFB7185);
  static const Color info = Color(0xFF60A5FA);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark();
  TextTheme textTheme;
  try {
    textTheme = GoogleFonts.dmSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textSecondary,
      displayColor: AppColors.text,
    );
  } catch (_) {
    textTheme = base.textTheme.apply(
      bodyColor: AppColors.textSecondary,
      displayColor: AppColors.text,
    );
  }
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    cardColor: AppColors.card,
    dividerColor: AppColors.border,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.info,
      surface: AppColors.card,
      error: AppColors.danger,
    ),
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textMuted,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
