import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Dark Theme Colors (existing)
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

// Light Theme Colors
class AppColorsLight {
  static const Color bg = Color(0xFFF8F9FC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardHover = Color(0xFFF3F4F6);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color text = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textDim = Color(0xFF9CA3AF);
  static const Color accent = Color(0xFF8B5CF6);
  static const Color accentHover = Color(0xFF7C3AED);
  static const Color sidebar = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}

// Theme Notifier
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode;
  static const String _themeKey = 'theme_mode';

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// [initialMode] should be the theme loaded from storage before runApp
  /// so the first frame uses the correct theme (no dark flash on refresh).
  ThemeNotifier([ThemeMode? initialMode]) : _themeMode = initialMode ?? ThemeMode.dark {
    _loadTheme(); // sync from storage (no extra notify if same)
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey) ?? 'dark';
      final mode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
      if (_themeMode != mode) {
        _themeMode = mode;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode == ThemeMode.light ? 'light' : 'dark');
    } catch (_) {}
  }

  void toggleTheme() {
    setThemeMode(_themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }
}

// Dark Theme
ThemeData buildDarkTheme() {
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
      brightness: Brightness.dark,
    ),
    textTheme: textTheme,
    iconTheme: const IconThemeData(
      color: AppColors.textSecondary,
      size: 24,
    ),
    primaryIconTheme: const IconThemeData(
      color: AppColors.accent,
      size: 24,
    ),
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
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accent;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: AppColors.border, width: 1.5),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    ),
  );
}

// Light Theme
ThemeData buildLightTheme() {
  final base = ThemeData.light();
  TextTheme textTheme;
  try {
    textTheme = GoogleFonts.dmSansTextTheme(base.textTheme).apply(
      bodyColor: AppColorsLight.textSecondary,
      displayColor: AppColorsLight.text,
    );
  } catch (_) {
    textTheme = base.textTheme.apply(
      bodyColor: AppColorsLight.textSecondary,
      displayColor: AppColorsLight.text,
    );
  }
  return base.copyWith(
    scaffoldBackgroundColor: AppColorsLight.bg,
    cardColor: AppColorsLight.card,
    dividerColor: AppColorsLight.border,
    colorScheme: const ColorScheme.light(
      primary: AppColorsLight.accent,
      secondary: AppColorsLight.info,
      surface: AppColorsLight.card,
      error: AppColorsLight.danger,
      brightness: Brightness.light,
    ),
    textTheme: textTheme,
    iconTheme: const IconThemeData(
      color: AppColorsLight.textSecondary,
      size: 24,
    ),
    primaryIconTheme: const IconThemeData(
      color: AppColorsLight.accent,
      size: 24,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColorsLight.bg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsLight.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsLight.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsLight.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsLight.accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColorsLight.textDim, fontSize: 13),
      labelStyle: const TextStyle(color: AppColorsLight.textMuted, fontSize: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsLight.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorsLight.textSecondary,
        side: const BorderSide(color: AppColorsLight.border),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColorsLight.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColorsLight.text,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        color: AppColorsLight.textSecondary,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColorsLight.accent;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: AppColorsLight.border, width: 1.5),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsLight.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsLight.border),
        ),
      ),
    ),
  );
}

// Helper to get current theme colors based on context
extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  Color get bgColor => isDarkMode ? AppColors.bg : AppColorsLight.bg;
  Color get cardColor => isDarkMode ? AppColors.card : AppColorsLight.card;
  Color get cardHoverColor => isDarkMode ? AppColors.cardHover : AppColorsLight.cardHover;
  Color get borderColor => isDarkMode ? AppColors.border : AppColorsLight.border;
  Color get borderLightColor => isDarkMode ? AppColors.borderLight : AppColorsLight.borderLight;
  Color get textColor => isDarkMode ? AppColors.text : AppColorsLight.text;
  Color get textSecondaryColor => isDarkMode ? AppColors.textSecondary : AppColorsLight.textSecondary;
  Color get textMutedColor => isDarkMode ? AppColors.textMuted : AppColorsLight.textMuted;
  Color get textDimColor => isDarkMode ? AppColors.textDim : AppColorsLight.textDim;
  Color get accentColor => isDarkMode ? AppColors.accent : AppColorsLight.accent;
  Color get accentHoverColor => isDarkMode ? AppColors.accentHover : AppColorsLight.accentHover;
  Color get sidebarColor => isDarkMode ? AppColors.sidebar : AppColorsLight.sidebar;
  Color get successColor => isDarkMode ? AppColors.success : AppColorsLight.success;
  Color get warningColor => isDarkMode ? AppColors.warning : AppColorsLight.warning;
  Color get dangerColor => isDarkMode ? AppColors.danger : AppColorsLight.danger;
  Color get infoColor => isDarkMode ? AppColors.info : AppColorsLight.info;
}

// Backward compatibility
@Deprecated('Use buildDarkTheme() instead')
ThemeData buildAppTheme() => buildDarkTheme();
