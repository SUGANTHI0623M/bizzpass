import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_colors.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_color';
  static const String _darkModeKey = 'dark_mode';

  Color _primaryColor = const Color(0xFFFFB300);
  bool _isDarkMode = true; // Default to dark to match reference

  Color get primaryColor => _primaryColor;
  bool get isDarkMode => _isDarkMode;

  final List<Color> themeColors = [
    const Color(0xFFFFB300),
    const Color(0xFF43A047),
    const Color(0xFF1E88E5),
    const Color(0xFFE53935),
    const Color(0xFF8E24AA),
    const Color(0xFFFB8C00),
    const Color(0xFFE91E63),
    const Color(0xFF000000),
  ];

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_themeKey);
    final darkMode = prefs.getBool(_darkModeKey);
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
      AppColors.updateTheme(_primaryColor);
    }
    if (darkMode != null) {
      _isDarkMode = darkMode;
    }
    notifyListeners();
  }

  Future<void> setThemeColor(Color color) async {
    _primaryColor = color;
    AppColors.updateTheme(color);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, color.value);
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<void> toggleDarkMode() async {
    await setDarkMode(!_isDarkMode);
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors = AppThemeColors(isDark: isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: _primaryColor,
        onPrimary: isDark ? const Color(0xFF1A1E29) : Colors.white,
        secondary: _primaryColor.withValues(alpha: 0.8),
        onSecondary: isDark ? const Color(0xFF1A1E29) : Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: colors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        iconTheme: IconThemeData(color: _primaryColor, size: 22),
        actionsIconTheme: IconThemeData(color: _primaryColor, size: 22),
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: TextStyle(color: colors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: isDark ? const Color(0xFF1A1E29) : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: BorderSide(color: _primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: _primaryColor,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  ThemeData get lightTheme => _buildTheme(Brightness.light);
  ThemeData get darkTheme => _buildTheme(Brightness.dark);

  /// For backwards compatibility - returns theme for current mode.
  ThemeData getThemeData() => _isDarkMode ? darkTheme : lightTheme;
}
