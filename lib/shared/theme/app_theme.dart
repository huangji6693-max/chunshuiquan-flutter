import 'package:flutter/material.dart';

/// 春水圈主题 — Material 3 暗色主题
/// 核心原则：
/// 1. ColorScheme.fromSeed 自动生成 7 级 surface 灰阶
/// 2. 不同层级的组件用不同 surface：
///    - 背景(surface) < 导航栏(surfaceContainer) < 卡片(surfaceContainerHigh)
///    - < 弹窗/输入框(surfaceContainerHighest)
/// 3. 品牌色只用于装饰性渐变，不用于基础组件
/// 4. 文字用 onSurface/onSurfaceVariant/outline 三级层次
class AppTheme {
  static const _seed = Color(0xFFFF4D88);

  // 品牌渐变（仅用于特殊装饰元素）
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFFF4D88), Color(0xFFFF6B9D)],
  );
  static const accentGradient = LinearGradient(
    colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
  );

  static final theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // 核心色系——fromSeed 自动生成全套暗色和谐色
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF101014),
      surfaceContainer: const Color(0xFF1A1A1E),
      surfaceContainerHigh: const Color(0xFF232328),
      surfaceContainerHighest: const Color(0xFF2C2C32),
    ),

    // 排版——精致的字重和字间距层级
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.3),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.43),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    ),

    // AppBar——与背景同色，不抢视觉焦点
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1, // 滚动时微微提升
      surfaceTintColor: null, // 让 M3 自动处理 tint
    ),

    // 按钮
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),

    // 输入框——比卡片更亮一级 (surfaceContainerHighest)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      // fillColor 不设，让 M3 自动用 surfaceContainerHighest
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

    // 卡片——elevation 1，M3 会自动添加 surface tint 让卡片比背景亮
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
    ),

    // BottomSheet——elevation 自动处理
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      elevation: 3,
    ),

    // NavigationBar
    navigationBarTheme: const NavigationBarThemeData(
      elevation: 2,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      thickness: 0.5,
      space: 0,
    ),

    // ListTile
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    // Dialog——高 elevation，最亮的浮层
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 6,
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
    ),

    // Chip
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // 关键：启用 elevation overlay（暗色下用 surface tint 表现深度）
    // Material 3 默认启用
  );
}
