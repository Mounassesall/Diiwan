import 'package:flutter/material.dart';

class DiiwanTheme {
  // Dark colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  // Light colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFCBD5E1);

  // Common colors
  static const Color primary = Color(0xFF10B981);
  static const Color primaryHover = Color(0xFF059669);

  // Dynamic getters based on brightness
  static Color background(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color surface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color textPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color botBubbleBg(bool isDark) => isDark ? darkSurface : const Color(0xFFE2E8F0);
  static Color userBubbleBg(bool isDark) => primary;
  static Color warningBg(bool isDark) => isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7);
  static Color warningText(bool isDark) => isDark ? const Color(0xFFFDBA74) : const Color(0xFF92400E);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryHover,
        surface: darkSurface,
        background: darkBackground,
        onPrimary: Colors.white,
        onSurface: darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primary),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: darkTextPrimary, fontFamily: 'Inter'),
        bodyMedium: TextStyle(color: darkTextPrimary, fontFamily: 'Inter'),
        titleLarge: TextStyle(color: darkTextPrimary, fontFamily: 'Inter', fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: primary),
        ),
        hintStyle: const TextStyle(color: darkTextSecondary),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryHover,
        surface: lightSurface,
        background: lightBackground,
        onPrimary: Colors.white,
        onSurface: lightTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primary),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: lightTextPrimary, fontFamily: 'Inter'),
        bodyMedium: TextStyle(color: lightTextPrimary, fontFamily: 'Inter'),
        titleLarge: TextStyle(color: lightTextPrimary, fontFamily: 'Inter', fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: primary),
        ),
        hintStyle: const TextStyle(color: lightTextSecondary),
      ),
    );
  }
}
