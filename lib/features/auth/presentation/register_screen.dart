import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/theme/design_tokens.dart';

/// 注册页 — Hinge 风格沉浸式大图 + 玻璃表单
/// 上半部分人像大图 + 渐变蒙层, 下半部分 BackdropFilter 玻璃表单
/// 删除: emoji 性别选择 / 白色 Material 卡片 / 白色按钮 / 波浪装饰
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  static const _heroImage =
      'https://images.unsplash.com/photo-1516589091380-5d8e87df6999?w=1600&q=90&fit=crop&auto=format';

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _gender = 'male';
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(authRepositoryProvider);
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    try {
      await repo.register(
        name: email.split('@')[0],
        email: email,
        password: password,
        birthDate: '2000-01-01',
        gender: _gender,
      );
      if (mounted) context.go('/onboarding');
    } on AppException catch (e) {
      // 邮箱已注册 → 自动用同密码尝试登录, 无缝救援
      if (e.isEmailExists) {
        try {
          await repo.login(email: email, password: password);
          if (mounted) context.go('/discover');
          return;
        } on AppException catch (_) {
          if (!mounted) return;
          setState(() => _error = '该邮箱已注册，密码不对。请直接登录');
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) context.go('/auth/login?email=$email');
          });
          return;
        }
      }
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 玻璃输入框 — 半透明白 + 1.5px 边框 + 圆角胶囊
  InputDecoration _glassInputDeco(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.85)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.12),
        labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3),
        floatingLabelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Dt.pink, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Dt.pink.withValues(alpha: 0.7), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Dt.pink, width: 1.8),
        ),
        errorStyle: const TextStyle(
            color: Dt.pinkLight, fontSize: 12, fontWeight: FontWeight.w500),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Dt.bgDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 全屏背景大图 (Hinge 风格)
          CachedNetworkImage(
            imageUrl: _heroImage,
            fit: BoxFit.cover,
            placeholder: (_, __) => const ColoredBox(color: Dt.bgDeep),
            errorWidget: (_, __, ___) => const ColoredBox(color: Dt.bgDeep),
          ),

          // 三层渐变蒙层 — 上→透明 / 中→半暗 / 下→深暗 (让表单可读)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x80000000),  // 顶部 50% 黑
                    Color(0x33000000),  // 上中 20% 黑
                    Color(0xCC0A0614),  // 下中 80% 深紫黑
                    Color(0xFF07080A),  // 底部 接近纯黑
                  ],
                  stops: [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // 顶部返回按钮 + 品牌 logo
          Positioned(
            top: mq.padding.top + 12,
            left: 8,
            right: 8,
            child: Row(
              children: [
                _GlassIconBtn(
                  icon: Icons.arrow_back_ios_rounded,
                  onTap: () => context.pop(),
                ),
                const Spacer(),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Dt.pinkLight, Dt.pink, Color(0xFFE8366D)],
                      stops: [0.0, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Dt.pink.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                const Text('春水圈',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(color: Color(0x80000000), blurRadius: 12),
                      ],
                    )),
                const Spacer(),
                const SizedBox(width: 44),
              ],
            ),
          ),

          // 主内容 — 底部 65% 玻璃表单
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: mq.size.height * 0.30,
            child: SafeArea(
              top: false,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(28, 24, 28, mq.padding.bottom + 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 大字标题 — Hinge 宣言
                        const Text(
                          '创建你的\n春水圈',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                            letterSpacing: -1.0,
                            shadows: [
                              Shadow(color: Color(0xCC000000), blurRadius: 24),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '此刻，开启心动旅程',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                            shadows: const [
                              Shadow(color: Color(0x99000000), blurRadius: 12),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 玻璃表单容器 — BackdropFilter
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Dt.pink.withValues(alpha: 0.15),
                                    blurRadius: 32,
                                    spreadRadius: -4,
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 邮箱
                                    TextFormField(
                                      key: const Key('email'),
                                      controller: _emailCtrl,
                                      decoration: _glassInputDeco('邮箱', Icons.mail_outline_rounded),
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500),
                                      validator: (v) =>
                                          v == null || !v.contains('@')
                                              ? '请输入有效邮箱'
                                              : null,
                                    ),
                                    const SizedBox(height: 14),

                                    // 密码
                                    TextFormField(
                                      key: const Key('password'),
                                      controller: _passCtrl,
                                      decoration: _glassInputDeco('密码', Icons.lock_outline_rounded)
                                          .copyWith(
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscure
                                                ? Icons.visibility_off_rounded
                                                : Icons.visibility_rounded,
                                            color: Colors.white.withValues(alpha: 0.6),
                                            size: 20,
                                          ),
                                          onPressed: () => setState(
                                              () => _obscure = !_obscure),
                                        ),
                                      ),
                                      obscureText: _obscure,
                                      textInputAction: TextInputAction.done,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500),
                                      validator: (v) => v == null || v.length < 6
                                          ? '密码至少 6 位'
                                          : null,
                                    ),
                                    const SizedBox(height: 22),

                                    // 性别选择 — 自绘 icon, 无 emoji
                                    Text('我是',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withValues(alpha: 0.65),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.5,
                                        )),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _GenderPill(
                                            icon: Icons.male_rounded,
                                            label: '男生',
                                            color: const Color(0xFF5B9AFF),
                                            selected: _gender == 'male',
                                            onTap: () => setState(() => _gender = 'male'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _GenderPill(
                                            icon: Icons.female_rounded,
                                            label: '女生',
                                            color: Dt.pink,
                                            selected: _gender == 'female',
                                            onTap: () => setState(() => _gender = 'female'),
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (_error != null) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Dt.pink.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Dt.pink.withValues(alpha: 0.5),
                                              width: 1),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.error_outline_rounded,
                                                color: Dt.pinkLight, size: 16),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(_error!,
                                                  style: const TextStyle(
                                                    color: Dt.pinkLight,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  )),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 渐变发光大 CTA — 与 welcome 一致
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Dt.pink, Dt.pinkLight, Dt.orange],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(29),
                              boxShadow: [
                                BoxShadow(
                                  color: Dt.pink.withValues(alpha: 0.55),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                                BoxShadow(
                                  color: Dt.pink.withValues(alpha: 0.25),
                                  blurRadius: 60,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: const Key('register_btn'),
                                borderRadius: BorderRadius.circular(29),
                                onTap: _loading ? null : _register,
                                child: Center(
                                  child: _loading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '遇 见 心 动',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 2.5,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Icon(Icons.arrow_forward_rounded,
                                                color: Colors.white, size: 20),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 已有账号
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/auth/login'),
                            child: Text.rich(TextSpan(
                              text: '已有账号？',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                              children: const [
                                TextSpan(
                                  text: '立即登录',
                                  style: TextStyle(
                                    color: Dt.pink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 玻璃圆形按钮 (返回键)
class _GlassIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.35),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

/// 性别选择胶囊 — 自绘风格, 无 emoji
class _GenderPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _GenderPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.18),
            width: selected ? 1.8 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? color : Colors.white.withValues(alpha: 0.55),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white.withValues(alpha: 0.65),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
