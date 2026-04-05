import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/theme/design_tokens.dart';

/// 登录页 - 春水圈品牌风格
/// 背景渐变 + 波浪动画 + 精致输入框
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  // 入场动画
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // 波浪动画
  late final AnimationController _waveCtrl;

  // 登录按钮缩放动画
  late final AnimationController _btnCtrl;
  late final Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    // 波浪动画控制器
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // 按钮缩放
    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _btnScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _waveCtrl.dispose();
    _btnCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 渐变背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Dt.pink, Dt.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 波浪动画背景
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveCtrl,
              builder: (context, _) => CustomPaint(
                painter: _WavePainter(animation: _waveCtrl.value),
              ),
            ),
          ),

          // 主内容
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

                      // Logo 和品牌名
                      const Icon(Icons.favorite_rounded, color: Colors.white, size: 56),
                      const SizedBox(height: 12),
                      const Text(
                        '春水圈',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 6,
                          shadows: [
                            Shadow(
                              color: Color(0x40000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '遇见对的人',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white.withValues(alpha:0.85),
                          letterSpacing: 4,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // 表单区域 - 半透明毛玻璃风格
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha:0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha:0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('欢迎回来',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                              const SizedBox(height: 6),
                              Text('登录你的账号',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha:0.7))),
                              const SizedBox(height: 24),

                              // 邮箱输入框
                              TextFormField(
                                key: const Key('email'),
                                controller: _emailCtrl,
                                decoration: _frostInputDeco('邮箱', Icons.email_outlined),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                validator: (v) =>
                                    v == null || !v.contains('@') ? '请输入有效邮箱' : null,
                              ),
                              const SizedBox(height: 16),

                              // 密码输入框
                              TextFormField(
                                key: const Key('password'),
                                controller: _passCtrl,
                                decoration: _frostInputDeco('密码', Icons.lock_outline).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.white60,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                onFieldSubmitted: (_) => _login(),
                                validator: (v) =>
                                    v == null || v.length < 6 ? '密码至少6位' : null,
                              ),

                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha:0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(_error!,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // 登录按钮 - 白色按钮，文字粉红色，按压缩放
                              GestureDetector(
                                onTapDown: (_) => _btnCtrl.forward(),
                                onTapUp: (_) {
                                  _btnCtrl.reverse();
                                  if (!_loading) _login();
                                },
                                onTapCancel: () => _btnCtrl.reverse(),
                                child: AnimatedBuilder(
                                  animation: _btnScale,
                                  builder: (context, child) => Transform.scale(
                                    scale: _btnScale.value,
                                    child: child,
                                  ),
                                  child: Container(
                                    key: const Key('login_btn'),
                                    width: double.infinity,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(27),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha:0.15),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
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
                                                color: Dt.pink,
                                              ),
                                            )
                                          : const Text('登录',
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: Dt.pink,
                                                letterSpacing: 2,
                                              )),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 注册链接
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('没有账号？',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha:0.8),
                                  fontSize: 14)),
                          TextButton(
                            onPressed: () => context.push('/auth/register'),
                            child: const Text('立即注册',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 半透明毛玻璃风格输入框装饰
  InputDecoration _frostInputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withValues(alpha:0.12),
      labelStyle: TextStyle(color: Colors.white.withValues(alpha:0.7), fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha:0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha:0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.yellow.withValues(alpha:0.6)),
      ),
      errorStyle: const TextStyle(color: Colors.yellowAccent, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

/// 波浪动画 Painter
/// 使用 CustomPainter 绘制多层波浪，营造流动感
class _WavePainter extends CustomPainter {
  final double animation;
  _WavePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    // 第一层波浪 - 底部
    _drawWave(
      canvas, size,
      amplitude: 20,
      wavelength: size.width * 0.8,
      phase: animation * 2 * pi,
      yOffset: size.height * 0.82,
      color: Colors.white.withValues(alpha:0.06),
    );

    // 第二层波浪
    _drawWave(
      canvas, size,
      amplitude: 15,
      wavelength: size.width * 0.6,
      phase: animation * 2 * pi + 1.5,
      yOffset: size.height * 0.86,
      color: Colors.white.withValues(alpha:0.04),
    );

    // 第三层波浪
    _drawWave(
      canvas, size,
      amplitude: 12,
      wavelength: size.width * 1.0,
      phase: animation * 2 * pi + 3.0,
      yOffset: size.height * 0.90,
      color: Colors.white.withValues(alpha:0.03),
    );
  }

  void _drawWave(Canvas canvas, Size size, {
    required double amplitude,
    required double wavelength,
    required double phase,
    required double yOffset,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, yOffset);

    for (double x = 0; x <= size.width; x += 1) {
      final y = yOffset + amplitude * sin((2 * pi * x / wavelength) + phase);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.animation != animation;
}
