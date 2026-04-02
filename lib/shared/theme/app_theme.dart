import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 春水圈主题 — Material 3 暗色 + 亮色双主题
/// 使用 Poppins 英文字体 + 系统中文字体
/// 核心原则：
/// 1. Poppins 的几何感让数字和英文显得现代高端
/// 2. 中文自动 fallback 到系统字体（iOS=苹方, Android=思源）
/// 3. 不同层级的组件用不同 surface
/// 4. 品牌色只用于装饰性渐变
class AppTheme {
  static const _seed = Color(0xFFFF4D88);

  // 品牌渐变（仅用于特殊装饰元素）
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFFF4D88), Color(0xFFFF6B9D)],
  );
  static const accentGradient = LinearGradient(
    colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
  );

  // ====== 基于 Poppins 的 TextTheme ======

  static final _textTheme = GoogleFonts.poppinsTextTheme(const TextTheme(
    displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.1),
    headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.15),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.2),
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.25),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.3),
    titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.15, height: 1.4),
    titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.4),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.08, height: 1.6),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.05, height: 1.55),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.3, height: 1.5),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.15, height: 1.4),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.4, height: 1.33),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.4, height: 1.45),
  ));

  // ====== 共享组件样式 ======

  static const _appBarTheme = AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 1,
    surfaceTintColor: null,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    ),
  );

  static final _buttonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
    ),
  );

  static final _cardTheme = CardTheme(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.zero,
  );

  static const _bottomSheetTheme = BottomSheetThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    elevation: 3,
  );

  static const _navigationBarTheme = NavigationBarThemeData(elevation: 2);
  static const _dividerTheme = DividerThemeData(thickness: 0.5, space: 0);

  static final _listTileTheme = ListTileThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  );

  static final _dialogTheme = DialogTheme(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    elevation: 6,
  );

  static final _snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 3,
  );

  static final _chipTheme = ChipThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  // ====== 暗色主题 ======

  static final theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF101014),
      surfaceContainer: const Color(0xFF1A1A1E),
      surfaceContainerHigh: const Color(0xFF232328),
      surfaceContainerHighest: const Color(0xFF2C2C32),
    ),
    textTheme: _textTheme,
    appBarTheme: _appBarTheme,
    elevatedButtonTheme: _buttonTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _seed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: _cardTheme,
    bottomSheetTheme: _bottomSheetTheme,
    navigationBarTheme: _navigationBarTheme,
    dividerTheme: _dividerTheme,
    listTileTheme: _listTileTheme,
    dialogTheme: _dialogTheme,
    snackBarTheme: _snackBarTheme,
    chipTheme: _chipTheme,
  );

  // ====== 亮色主题 ======

  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ),
    textTheme: _textTheme,
    appBarTheme: _appBarTheme,
    elevatedButtonTheme: _buttonTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _seed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: _cardTheme,
    bottomSheetTheme: _bottomSheetTheme,
    navigationBarTheme: _navigationBarTheme,
    dividerTheme: _dividerTheme,
    listTileTheme: _listTileTheme,
    dialogTheme: _dialogTheme,
    snackBarTheme: _snackBarTheme,
    chipTheme: _chipTheme,
  );
}
