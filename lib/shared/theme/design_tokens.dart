import 'dart:ui';
import 'package:flutter/material.dart';

/// 春水圈 Design Token 系统 v4
/// 基于 awesome-design-md 全 58 个 DESIGN.md 深度学习提炼
///
/// v3 来源: Spotify/Linear/Stripe/Apple/Vercel/Superhuman/Airbnb/Coinbase/Raycast/Framer (10 品牌)
/// v4 新增: Sanity(夜空奢华映射) + Ferrari/Lamborghini(品牌色克制) + Pinterest(照片驱动)
///         + Sentry(生物发光过渡) + Tesla/Revolut/Wise(超紧 line-height)
///         + Composio/Lambo(色阶分层替代阴影)
///
/// 跨 58 品牌 5 大共识法则:
///   1. 阴影已死 — 边界 + 表面分层当道 (Lambo/Tesla/Sanity/Supabase 共证)
///   2. 超紧 lh 0.85-1.10 是奢华信号 (Lambo 0.92 / Wise 0.85 / Composio 0.87)
///   3. 字重单一化 500 主导，零 700+ (Cursor/Mistral/Tesla/Cal 共证)
///   4. 品牌色仅信号化，零装饰 (Spotify/Ferrari/Lambo/Pinterest 共证)
///   5. 摄影/内容是唯一颜色源 (Ferrari/Lambo/Tesla/SpaceX/Sanity/Pinterest 共证)
///
/// 核心哲学: "UI消失，人闪耀" — UI隐没于用户照片，品牌色仅点缀关键时刻

class Dt {
  Dt._();

  // ============================================================
  //  颜色 — 单一品牌色约束 (Spotify/Linear/Apple都只用1种accent)
  // ============================================================

  // 品牌色 — 暖玫瑰红 + 珊瑚渐变 (与电影感大图协调)
  // 主人反馈: 之前 #FF4D88 霓虹荧光粉太刺眼, 不搭温暖电影感
  // 升级到降饱和高级调: 玫瑰红 → 暖珊瑚 → 落日橙
  static const Color pink = Color(0xFFE63E5C);       // 玫瑰红 (主品牌)
  static const Color pinkLight = Color(0xFFFF6B7A);  // 暖珊瑚 (高光)
  static const Color orange = Color(0xFFFF8A5C);     // 落日橙 (渐变收尾)

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

  // [v4] 粉色"生物发光"过渡 (Sentry/Composio 启发)
  // 用于 focus ring / hover 层 / 微弱品牌点缀，禁止用作背景填充
  static const Color pinkGlow15 = Color(0x26FF4D88);  // 15% alpha
  static const Color pinkGlow30 = Color(0x4DFF4D88);  // 30% alpha

  // [v4] 粉色 1px 边界环 — 比 box-shadow 更高级的强调
  static const Color borderRingPink = Color(0x26FF4D88);  // 与 pinkGlow15 同值

  // 品牌渐变 (v3 保留向后兼容；v4 推荐零渐变, 仅 CTA 极端时使用)
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

  // [v4] 摄影覆盖渐变 (Ferrari/Renault/SpaceX 共识)
  // 用户照片底部统一覆盖, 提升文本可读性, 替代任何文本阴影
  static const LinearGradient photoOverlay = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xCC000000), Color(0x00000000)],  // 0.8 → 0.0
    stops: [0.0, 0.5],
  );

  // [v4] 暗色色阶分层 (Lamborghini #000→#181818→#202020 启发)
  // 用 List 表达"深度仅靠颜色分割"哲学
  static const List<Color> surfaceLayered = [
    bgDeep,      // #07080A — Z0 最深
    bgPrimary,   // #0F1012 — Z1 卡片底
    bgElevated,  // #161719 — Z2 提升表面
    bgHighest,   // #1E1F22 — Z3 浮层/模态
  ];

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

  // [v4] 超大段距 — 电影感留白 (Expo 96-144px / Revolut 80-120px / Sanity 64-120px 共识)
  // 用于 hero → CTA, section 之间, 营造"奢华隔离感"
  static const double s80 = 80;
  static const double s96 = 96;
  static const double s120 = 120;

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

  // [v4] 行高常量 — D 组共识: 超紧 lh 0.85-1.10 是奢华信号
  // (Lambo 0.92 / Wise 0.85 / Renault 0.95 / Composio 0.87 / Sentry 0.96)
  static const double lhDisplay = 0.95;   // hero / display, 0.92-1.05
  static const double lhHeading = 1.15;   // section heading, 1.10-1.25
  static const double lhBody = 1.50;      // 正文, 1.40-1.60
  static const double lhCaption = 1.40;   // 小字 / 标签

  // [v4] 字距常量 — Linear/Sanity/Composio 共识: 显示层负字距, 标签层正字距
  static const double tsDisplay = -0.6;   // 大尺寸压紧, -0.5~-0.8
  static const double tsHeading = -0.3;   // 中尺寸略压, -0.2~-0.4
  static const double tsBody = 0.0;       // 正文标准
  static const double tsLabel = 0.5;      // 小尺寸放宽, +0.4~+0.6 (Raycast/NVIDIA)

  // [v4] Mega Display (Lambo 120px / Revolut 136px 启发)
  // 仅用于启动页 / 匹配成功页 等"宣言时刻", 极少使用
  static const TextStyle displayMega = TextStyle(
    fontSize: 96,
    fontWeight: FontWeight.w600,  // 500-600 区间, Cursor/Mistral 共识
    height: 0.92,                  // Lambo 启发, 极紧
    letterSpacing: -2.4,
    color: textPrimary,
  );

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
  /// [v4 修复] 移除 v3 残留的 surfaceContainerHigh, 直接用 Dt.bgElevated
  static BoxDecoration cardDecoration() => BoxDecoration(
    color: bgElevated,
    borderRadius: rLg,
    boxShadow: shadowSm,
  );

  /// [v4 新增] 极简卡片 — Sanity/Lambo 启发: 仅靠色阶 + 1px ring
  /// 用于 Pinterest 风格 masonry / 用户照片网格 — 最大化"内容驱动"哲学
  static BoxDecoration cardMinimal({Color? color}) => BoxDecoration(
    color: color ?? bgElevated,
    borderRadius: rLg,
    border: Border.all(color: borderSubtle, width: 1),
  );

  /// [v4 新增] 粉色信号边界卡片 — 用于 Like 状态 / 焦点强调
  /// 不用 box-shadow 也能传达"高亮", 比品牌光晕装饰更克制
  static BoxDecoration cardPinkRing({Color? color}) => BoxDecoration(
    color: color ?? bgElevated,
    borderRadius: rLg,
    border: Border.all(color: borderRingPink, width: 1),
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
  static final BoxDecoration ctaButton = BoxDecoration(
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

  /// [v4 新增] 极简 CTA — Sanity/Ferrari 启发: 纯色 + pill, 无渐变无阴影
  /// "颜色对比就是深度", 移除装饰阴影
  static final BoxDecoration ctaButtonMinimal = BoxDecoration(
    color: pink,
    borderRadius: rPill,
  );

  /// [v4 新增] Pill 按钮 — Uber/Wise/Revolut/Mintlify 共识 9999px
  static final BoxDecoration pillButton = BoxDecoration(
    color: bgElevated,
    borderRadius: rPill,
    border: Border.all(color: borderMedium, width: 1),
  );
}
