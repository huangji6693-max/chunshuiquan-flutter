import 'package:flutter/material.dart';

/// 春水圈主题 — 高级荷尔蒙风
/// 深色底、粉紫渐变、毛玻璃、大阴影、有冲击力
class AppTheme {
  // 品牌色系
  static const primary = Color(0xFFFF4D88);
  static const primaryDark = Color(0xFFE91E6C);
  static const accent = Color(0xFFFF6B9D);
  static const purple = Color(0xFF8B5CF6);
  static const deepPurple = Color(0xFF6C3FB5);
  static const gradientStart = Color(0xFFFF4D88);
  static const gradientEnd = Color(0xFFFF8A5C);
  static const bgDark = Color(0xFF0F0A1A);
  static const bgCard = Color(0xFF1A1230);
  static const bgSurface = Color(0xFFF5F0FA);

  // 渐变预设
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
  );
  static const purpleGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFFF4D88)],
  );
  static const darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A0E2E), Color(0xFF0F0A1A)],
  );

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      secondary: purple,
    ),
    scaffoldBackgroundColor: bgDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F0A1A),
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: primary.withOpacity(0.4),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1230),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    cardTheme: CardTheme(
      elevation: 8,
      shadowColor: primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bgDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accent,
      secondary: purple,
      surface: bgCard,
    ),
  );
}
