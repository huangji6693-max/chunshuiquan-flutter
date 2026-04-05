import 'package:flutter/material.dart';

/// 春水圈 Design Token 系统
/// 所有UI数值的唯一真理源——禁止在组件中硬编码
///
/// 使用方式：
///   Dt.s16          → 16.0 间距
///   Dt.r16          → BorderRadius.circular(16)
///   Dt.fast          → Duration(milliseconds: 200)
///   Dt.shadowSm      → 小阴影
///   Dt.pink          → 品牌粉

class Dt {
  Dt._();

  // ============================================================
  //  颜色 — 品牌色 + 语义色
  // ============================================================

  // 品牌色
  static const Color pink = Color(0xFFFF4D88);
  static const Color pinkLight = Color(0xFFFF6B9D);
  static const Color orange = Color(0xFFFF8A5C);

  // 功能色
  static const Color like = Color(0xFF4CAF50);
  static const Color nope = Color(0xFFFF5A5A);
  static const Color superLike = Color(0xFF5B9AFF);
  static const Color boost = Color(0xFF7C4DFF);
  static const Color vipGold = Color(0xFFFFD700);
  static const Color vipGoldDark = Color(0xFFFFA000);
  static const Color online = Color(0xFF4CAF50);

  // 品牌渐变
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [pink, pinkLight],
  );
  static const LinearGradient gradientAccent = LinearGradient(
    colors: [pink, orange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient gradientVip = LinearGradient(
    colors: [vipGold, vipGoldDark],
  );

  // ============================================================
  //  间距 — 严格 8px 网格
  // ============================================================

  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;   // 8的1.5倍，允许
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
  static const double s64 = 64;

  // ============================================================
  //  圆角 — 只有4个档位
  // ============================================================

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusRound = 999;  // 胶囊/圆形

  static final BorderRadius rSm = BorderRadius.circular(radiusSm);
  static final BorderRadius rMd = BorderRadius.circular(radiusMd);
  static final BorderRadius rLg = BorderRadius.circular(radiusLg);
  static final BorderRadius rXl = BorderRadius.circular(radiusXl);

  // ============================================================
  //  阴影 — 3个档位
  // ============================================================

  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  // 彩色发光（用于按钮/卡片）
  static List<BoxShadow> glow(Color color, {double alpha = 0.2, double blur = 16}) => [
    BoxShadow(
      color: color.withValues(alpha: alpha),
      blurRadius: blur,
      offset: const Offset(0, 4),
    ),
  ];

  // ============================================================
  //  动画 — 统一时长和曲线
  // ============================================================

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveSpring = Curves.easeOutBack;

  // ============================================================
  //  毛玻璃参数
  // ============================================================

  static const double blurLight = 8;
  static const double blurMedium = 15;
  static const double blurHeavy = 20;

  // ============================================================
  //  边框
  // ============================================================

  static BorderSide borderSubtle(BuildContext context) => BorderSide(
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.15),
    width: 0.5,
  );

  static BorderSide borderMedium(BuildContext context) => BorderSide(
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
    width: 1,
  );

  // ============================================================
  //  常用组合
  // ============================================================

  /// 卡片装饰（统一用这个）
  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    borderRadius: rLg,
    border: Border.all(
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.1),
      width: 0.5,
    ),
    boxShadow: shadowSm,
  );

  /// 毛玻璃按钮装饰
  static BoxDecoration glassButton(Color accentColor) => BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.white.withValues(alpha: 0.1),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.15),
      width: 1,
    ),
    boxShadow: glow(accentColor),
  );
}
