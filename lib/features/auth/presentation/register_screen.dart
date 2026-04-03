import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../../../core/errors/app_exception.dart';

/// 注册页 - 步骤式注册，精致卡片选择器
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
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

  // 波浪动画
  late final AnimationController _waveCtrl;

  // 按钮缩放
  late final AnimationController _btnCtrl;
  late final Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final email = _emailCtrl.text.trim();
      await ref.read(authRepositoryProvider).register(
        name: email.split('@')[0],
        email: email,
        password: _passCtrl.text,
        birthDate: '2000-01-01',
        gender: _gender,
      );
      if (mounted) context.go('/onboarding');
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 半透明输入框样式
  InputDecoration _frostInputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha:0.12),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha:0.7), fontSize: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha:0.3))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha:0.25))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.yellow.withValues(alpha:0.6)),
        ),
        errorStyle: const TextStyle(color: Colors.yellowAccent, fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 渐变背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 波浪动画
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
                child: Column(
                  children: [
                    // 顶部栏
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios,
                                color: Colors.white),
                            onPressed: () => context.pop(),
                          ),
                          const Spacer(),
                          const Icon(Icons.favorite_rounded, color: Colors.white, size: 48),
                          const SizedBox(width: 8),
                          const Text('春水圈',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                              )),
                          const Spacer(),
                          const SizedBox(width: 48), // 平衡返回按钮
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 副标题
                    Text(
                      '创建你的专属档案',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha:0.75),
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha:0.3),
                              width: 1,
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('几步就好',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                                const SizedBox(height: 6),
                                Text('三步开启你的心动之旅',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withValues(alpha:0.7))),
                                const SizedBox(height: 24),

                                // 邮箱
                                TextFormField(
                                  key: const Key('email'),
                                  controller: _emailCtrl,
                                  decoration: _frostInputDeco('邮箱', Icons.email_outlined),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
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
                                  decoration:
                                      _frostInputDeco('密码', Icons.lock_outline)
                                          .copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white60,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                          () => _obscure = !_obscure),
                                    ),
                                  ),
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                  validator: (v) => v == null || v.length < 6
                                      ? '密码至少6位'
                                      : null,
                                ),
                                const SizedBox(height: 18),

                                // 性别选择 - 精致卡片选择器
                                Text('性别',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withValues(alpha:0.7),
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _GenderCard(
                                        icon: Icons.male,
                                        label: '男生',
                                        emoji: '👨',
                                        selected: _gender == 'male',
                                        onTap: () =>
                                            setState(() => _gender = 'male'),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _GenderCard(
                                        icon: Icons.female,
                                        label: '女生',
                                        emoji: '👩',
                                        selected: _gender == 'female',
                                        onTap: () =>
                                            setState(() => _gender = 'female'),
                                      ),
                                    ),
                                  ],
                                ),

                                if (_error != null) ...[
                                  const SizedBox(height: 14),
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

                                // 注册按钮 - 白色按钮带缩放
                                GestureDetector(
                                  onTapDown: (_) => _btnCtrl.forward(),
                                  onTapUp: (_) {
                                    _btnCtrl.reverse();
                                    if (!_loading) _register();
                                  },
                                  onTapCancel: () => _btnCtrl.reverse(),
                                  child: AnimatedBuilder(
                                    animation: _btnScale,
                                    builder: (context, child) => Transform.scale(
                                      scale: _btnScale.value,
                                      child: child,
                                    ),
                                    child: Container(
                                      key: const Key('register_btn'),
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
                                                  color: Color(0xFFFF4D88),
                                                ),
                                              )
                                            : const Text('遇见心动 →',
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFFFF4D88),
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 性别选择卡片 - 精致设计
class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.icon,
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha:0.3)
              : Colors.white.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withValues(alpha:0.2),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha:0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 6),
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 波浪 Painter（与登录页一致）
class _WavePainter extends CustomPainter {
  final double animation;
  _WavePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(canvas, size,
        amplitude: 18, wavelength: size.width * 0.8,
        phase: animation * 2 * pi, yOffset: size.height * 0.84,
        color: Colors.white.withValues(alpha:0.05));
    _drawWave(canvas, size,
        amplitude: 14, wavelength: size.width * 0.6,
        phase: animation * 2 * pi + 1.5, yOffset: size.height * 0.88,
        color: Colors.white.withValues(alpha:0.04));
  }

  void _drawWave(Canvas canvas, Size size, {
    required double amplitude, required double wavelength,
    required double phase, required double yOffset, required Color color,
  }) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()..moveTo(0, yOffset);
    for (double x = 0; x <= size.width; x += 1) {
      path.lineTo(x, yOffset + amplitude * sin((2 * pi * x / wavelength) + phase));
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.animation != animation;
}
