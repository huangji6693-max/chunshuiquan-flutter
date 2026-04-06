import 'dart:ui';
import 'package:flutter/material.dart';

/// 春水圈 Design Token 系统 v2
/// 基于56个世界顶级品牌设计系统提炼
///
/// 参考: Spotify(暗色), Linear(极简), Stripe(精致), Raycast(暗色工具),
///       Superhuman(奢华), Airbnb(温暖), Vercel(边框即阴影)
///
/// 核心哲学: "UI消失，人闪耀" — UI隐没于用户照片，品牌色仅点缀关键时刻

class Dt {
  Dt._();

  // ============================================================
  //  颜色 — 单一品牌色约束 (Spotify/Linear/Apple都只用1种accent)
  // ============================================================

  // 品牌色 — 仅用于Like/CTA/匹配通知，禁止装饰
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

  // 暗色主题色阶 (Raycast风格蓝着色黑 #07080a, 非纯黑)
  static const Color bgDeep = Color(0xFF07080A);      // 最深背景
  static const Color bgPrimary = Color(0xFF0F1012);    // 主背景
  static const Color bgElevated = Color(0xFF161719);   // 卡片/提升表面
  static const Color bgHighest = Color(0xFF1E1F22);    // 最高表面/模态

  // 文本色 (Linear: #f7f8f8/#d0d6e0/#8a8f98)
  static const Color textPrimary = Color(0xFFF5F5F7);  // 主文本(非纯白)
  static const Color textSecondary = Color(0xFFA8A8B0); // 次要文本
  static const Color textTertiary = Color(0xFF6B6B73);  // 三级文本

  // 边框 (Vercel: 影子即边框, rgba(255,255,255,0.06-0.08))
  static const Color borderSubtle = Color(0x14FFFFFF);  // 8% 白色
  static const Color borderMedium = Color(0x1FFFFFFF);  // 12% 白色

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
  //  间距 — 8px网格 (所有顶级品牌统一标准)
  // ============================================================

  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
  static const double s64 = 64;

  // ============================================================
  //  圆角 — 二进制系统 (Superhuman: 只有8和16, 加上药丸)
  // ============================================================

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusPill = 64;  // 大药丸按钮 (Uber/Spotify)

  static final BorderRadius rSm = BorderRadius.circular(radiusSm);
  static final BorderRadius rMd = BorderRadius.circular(radiusMd);
  static final BorderRadius rLg = BorderRadius.circular(radiusLg);
  static final BorderRadius rXl = BorderRadius.circular(radiusXl);
  static final BorderRadius rPill = BorderRadius.circular(radiusPill);

  // ============================================================
  //  阴影 — 多层堆栈 (Airbnb 3层, Raycast 5层, Vercel边框即阴影)
  // ============================================================

  /// Vercel风格: 影子即边框 (替代真实border)
  static List<BoxShadow> get shadowBorder => [
    const BoxShadow(
      color: Color(0x14FFFFFF), // rgba(255,255,255,0.08)
      blurRadius: 0,
      spreadRadius: 1, // 1px边框效果
    ),
  ];

  /// 轻阴影 (标准卡片)
  static List<BoxShadow> get shadowSm => [
    const BoxShadow(
      color: Color(0x14FFFFFF),   // 边框环
      blurRadius: 0,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// 中等阴影 (Airbnb 3层标准)
  static List<BoxShadow> get shadowMd => [
    const BoxShadow(
      color: Color(0x14FFFFFF),   // Layer 1: 边框环
      blurRadius: 0,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// 大阴影 + 品牌光晕 (匹配通知/重要操作)
  static List<BoxShadow> get shadowLg => [
    const BoxShadow(
      color: Color(0x1AFFFFFF),   // 边框环(稍亮)
      blurRadius: 0,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: pink.withValues(alpha: 0.15),  // 品牌光晕
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  /// 彩色发光 (用于按钮/卡片accent)
  static List<BoxShadow> glow(Color color, {double alpha = 0.2, double blur = 16}) => [
    BoxShadow(
      color: color.withValues(alpha: alpha),
      blurRadius: blur,
      offset: const Offset(0, 4),
    ),
  ];

  // ============================================================
  //  动画 (Spotify: 快速简洁, Apple: 0.33s cubic-bezier)
  // ============================================================

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveSpring = Curves.easeOutBack;

  // ============================================================
  //  毛玻璃 (Apple: translucent dark + blur)
  // ============================================================

  static const double blurLight = 10;
  static const double blurMedium = 15;
  static const double blurHeavy = 25;

  // ============================================================
  //  排版参数 (Superhuman: 0.96行高显示 + 1.5正文, 负字间距)
  // ============================================================

  // 显示文本: 紧凑行高 + 负字间距 = 视觉冲击
  static const TextStyle displayHero = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 0.96,
    letterSpacing: -1.8,
    color: textPrimary,
  );

  // 大标题
  static const TextStyle headingLg = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.6,
    color: textPrimary,
  );

  // 中标题
  static const TextStyle headingMd = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.3,
    color: textPrimary,
  );

  // 正文 (Raycast: weight 500基线 + 正字间距 +0.1)
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
    color: textPrimary,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.1,
    color: textSecondary,
  );

  // 标签 (正字间距 +0.2, Raycast风格)
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.4,
    color: textSecondary,
  );

  // ============================================================
  //  组合装饰 — 预置常用组合
  // ============================================================

  /// 标准卡片 (Vercel影子边框 + Airbnb多层阴影)
  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    borderRadius: rLg,
    boxShadow: shadowSm,
  );

  /// 毛玻璃按钮 (Raycast风格: 半透明 + 品牌光晕)
  static BoxDecoration glassButton(Color accentColor) => BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.white.withValues(alpha: 0.08),
    boxShadow: [
      ...shadowBorder,
      ...glow(accentColor, alpha: 0.2, blur: 16),
    ],
  );

  /// 品牌CTA按钮样式 (Spotify药丸)
  static BoxDecoration ctaButton = BoxDecoration(
    gradient: gradientAccent,
    borderRadius: rLg,
    boxShadow: [
      BoxShadow(
        color: pink.withValues(alpha: 0.3),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
