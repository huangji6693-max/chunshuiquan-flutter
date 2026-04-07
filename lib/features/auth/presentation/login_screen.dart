import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/theme/design_tokens.dart';

/// 登录页 — Hinge 风格沉浸式大图玻璃表单
/// 与 register_screen 对齐, 删除粉橙渐变 + 波浪装饰
class LoginScreen extends ConsumerStatefulWidget {
  /// 可选预填邮箱 (注册页 409 救援时使用)
  final String? prefilledEmail;
  const LoginScreen({super.key, this.prefilledEmail});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  // 与 register_screen 用不同的图制造连贯但不重复的视觉
  static const _heroImage =
      'https://images.unsplash.com/photo-1542596594-649edbc13630?w=1600&q=90&fit=crop&auto=format';

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
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

    // 预填邮箱 (注册页 409 救援)
    if (widget.prefilledEmail != null) {
      _emailCtrl.text = widget.prefilledEmail!;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ref.read(authRepositoryProvider).login(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          );
      if (mounted) {
        context.go(user.onboardingCompleted ? '/discover' : '/onboarding');
      }
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 玻璃输入框
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
          // 全屏背景大图
          CachedNetworkImage(
            imageUrl: _heroImage,
            fit: BoxFit.cover,
            placeholder: (_, __) => const ColoredBox(color: Dt.bgDeep),
            errorWidget: (_, __, ___) => const ColoredBox(color: Dt.bgDeep),
          ),

          // 4 层渐变蒙层
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x80000000),
                    Color(0x33000000),
                    Color(0xCC0A0614),
                    Color(0xFF07080A),
                  ],
                  stops: [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // 顶部返回 + logo
          Positioned(
            top: mq.padding.top + 12,
            left: 8,
            right: 8,
            child: Row(
              children: [
                _GlassIconBtn(
                  icon: Icons.arrow_back_ios_rounded,
                  onTap: () => context.canPop() ? context.pop() : context.go('/welcome'),
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

          // 玻璃表单
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: mq.size.height * 0.32,
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
                        const Text(
                          '欢迎\n回来',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                            letterSpacing: -1.2,
                            shadows: [
                              Shadow(color: Color(0xCC000000), blurRadius: 24),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '继续未完的故事',
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

                        // BackdropFilter 玻璃表单
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
                                      validator: (v) => v == null || !v.contains('@')
                                          ? '请输入有效邮箱'
                                          : null,
                                    ),
                                    const SizedBox(height: 14),
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
                                      onFieldSubmitted: (_) => _login(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500),
                                      validator: (v) => v == null || v.length < 6
                                          ? '密码至少 6 位'
                                          : null,
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

                        // 渐变发光大 CTA
                        GestureDetector(
                          key: const Key('login_btn'),
                          onTap: _loading ? null : _login,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: double.infinity,
                            height: 58,
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
                                          '登 录',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 4,
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

                        const SizedBox(height: 16),

                        // 还没账号
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/auth/register'),
                            child: Text.rich(TextSpan(
                              text: '还没账号？',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                              children: const [
                                TextSpan(
                                  text: '立即注册',
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

/// 玻璃圆形按钮
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
