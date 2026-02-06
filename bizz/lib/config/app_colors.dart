import 'package:flutter/material.dart';

/// Theme-aware colors. Use [AppColors.of(context)] or pass [isDark].
class AppColors {
  AppColors._();

  // --- Primary (user-selectable, used for accents) ---
  static Color primary = const Color(0xFFFFB300);
  static Color primaryDark = const Color(0xFFFF8F00);
  static Color primaryLight = const Color(0xFFFFE082);

  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primaryDark],
      );

  // --- Status (theme-independent) ---
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF039BE5);

  // --- Light theme ---
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardSurface = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE8ECF0);
  static const Color lightTextPrimary = Color(0xFF263238);
  static const Color lightTextSecondary = Color(0xFF78909C);

  // --- Dark theme ---
  static const Color darkBackground = Color(0xFF1A1E29);
  static const Color darkSurface = Color(0xFF2B2F3D);
  static const Color darkCardSurface = Color(0xFF2B2F3D);
  static const Color darkCardBorder = Color(0xFF3D4252);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B5C4);

  // --- Legacy / convenience (defaults to light for backwards compat) ---
  static const Color accent = Color(0xFFFFB300);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF78909C);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE8ECF0);
  static const Color divider = Color(0xFFECEFF1);

  static void updateTheme(Color color) {
    primary = color;
    primaryDark = _getDarkerColor(color);
    primaryLight = color.withValues(alpha: 0.5);
  }

  static Color _getDarkerColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }

  /// Theme-aware colors. Prefer [Theme.of(context)] when possible.
  static AppThemeColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppThemeColors(isDark: isDark);
  }

  /// Theme-aware colors from brightness.
  static AppThemeColors fromBrightness(bool isDark) => AppThemeColors(isDark: isDark);
}

/// Immutable theme-aware color set.
class AppThemeColors {
  final bool isDark;

  const AppThemeColors({required this.isDark});

  Color get background => isDark ? AppColors.darkBackground : AppColors.lightBackground;
  Color get surface => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get cardSurface => isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
  Color get cardBorder => isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
  Color get textPrimary => isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary => isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get primary => AppColors.primary;
  LinearGradient get primaryGradient => AppColors.primaryGradient;
}
