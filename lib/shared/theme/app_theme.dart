import 'package:flutter/material.dart';

/// 春水圈主题 — Material 3 暗色主题
/// 用 ColorScheme.fromSeed 生成和谐色系，不硬编码
class AppTheme {
  static const _seed = Color(0xFFFF4D88);

  // 品牌渐变（仅用于特殊装饰，不用于基础组件）
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFFF4D88), Color(0xFFFF6B9D)],
  );
  static const accentGradient = LinearGradient(
    colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
  );

  static final theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // 核心：让 Material 3 自动生成全套和谐暗色系
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),

    // 按钮
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),

    // 输入框
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _seed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // 卡片 — 用 outlined 风格，不依赖重阴影
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
    ),

    // BottomSheet
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
  );
}
