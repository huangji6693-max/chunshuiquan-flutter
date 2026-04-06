import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

/// 春水圈主题 v3 — 基于56个世界顶级品牌设计系统
///
/// 参考标杆:
/// - Raycast: 蓝着色黑 #07080a + 正字间距正文
/// - Linear: 极致简洁暗色 + 半透明白色边框
/// - Spotify: UI消失让内容闪耀 + 单一accent色
/// - Superhuman: 极端行高对比(0.96 vs 1.5) + 非标准字重
/// - Stripe: 精致排版 + 蓝色着色阴影
class AppTheme {
  static const _seed = Dt.pink;

  // 兼容旧代码引用
  static const Color brandPink = Dt.pink;
  static const primaryGradient = Dt.gradientPrimary;
  static const accentGradient = Dt.gradientAccent;

  // ====== Poppins TextTheme ======

  static final _textTheme = GoogleFonts.poppinsTextTheme(const TextTheme(
    // 极端压缩标题 (Superhuman 0.96行高, Framer -5.5px字间距)
    displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -1.2, height: 0.96),
    // 大标题
    headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6, height: 1.1),
    headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.2),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.1, height: 1.25),
    // 标题
    titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.3),
    titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.4),
    titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.4),
    // 正文 (Raycast: +0.1正字间距, 500基线权重)
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.55),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.5),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.2, height: 1.45),
    // 标签 (正字间距 +0.4, Raycast风格)
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.15, height: 1.4),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.4, height: 1.33),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.4, height: 1.45),
  ));

  // ====== AppBar ======

  static const _appBarTheme = AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0.5,
    surfaceTintColor: null,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
  );

  // ====== 按钮 (Spotify药丸形状) ======

  static final _buttonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dt.radiusLg)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      elevation: 0, // 扁平按钮, 阴影通过装饰添加
    ),
  );

  // ====== 卡片 (elevation 0, 用shadow-border替代) ======

  static final _cardTheme = CardTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dt.radiusLg)),
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.zero,
  );

  static const _bottomSheetTheme = BottomSheetThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Dt.radiusXl)),
    ),
    elevation: 0,
  );

  static const _dividerTheme = DividerThemeData(thickness: 0.5, space: 0);

  static final _listTileTheme = ListTileThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dt.radiusMd)),
    contentPadding: const EdgeInsets.symmetric(horizontal: Dt.s16, vertical: Dt.s4),
  );

  static final _dialogTheme = DialogTheme(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dt.radiusXl)),
    elevation: 0,
  );

  static final _snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dt.radiusMd)),
    elevation: 0,
  );

  static final _chipTheme = ChipThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dt.radiusSm)),
  );

  // ====== 输入框 ======

  static InputDecorationTheme _inputTheme(Brightness brightness) => InputDecorationTheme(
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dt.radiusMd),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dt.radiusMd),
      borderSide: BorderSide(
        color: brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dt.radiusMd),
      borderSide: const BorderSide(color: Dt.pink, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: Dt.s16, vertical: Dt.s16),
  );

  // ============================================================
  //  暗色主题 (Raycast: #07080a蓝着色黑)
  // ============================================================

  static final theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: Dt.bgPrimary,
      surfaceContainer: Dt.bgElevated,
      surfaceContainerHigh: Dt.bgHighest,
      surfaceContainerHighest: const Color(0xFF262729),
    ),
    scaffoldBackgroundColor: Dt.bgPrimary,
    textTheme: _textTheme,
    appBarTheme: _appBarTheme,
    elevatedButtonTheme: _buttonTheme,
    inputDecorationTheme: _inputTheme(Brightness.dark),
    cardTheme: _cardTheme,
    bottomSheetTheme: _bottomSheetTheme,
    dividerTheme: _dividerTheme,
    listTileTheme: _listTileTheme,
    dialogTheme: _dialogTheme,
    snackBarTheme: _snackBarTheme,
    chipTheme: _chipTheme,
    navigationBarTheme: const NavigationBarThemeData(elevation: 0),
  );

  // ============================================================
  //  亮色主题
  // ============================================================

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
    inputDecorationTheme: _inputTheme(Brightness.light),
    cardTheme: _cardTheme,
    bottomSheetTheme: _bottomSheetTheme,
    dividerTheme: _dividerTheme,
    listTileTheme: _listTileTheme,
    dialogTheme: _dialogTheme,
    snackBarTheme: _snackBarTheme,
    chipTheme: _chipTheme,
    navigationBarTheme: const NavigationBarThemeData(elevation: 0),
  );
}
