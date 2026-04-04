import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/upload_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  final List<File> _photos = [];
  final _bioCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String? _education;
  String _lookingFor = 'everyone';
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _bioCtrl.dispose();
    _jobCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1080, imageQuality: 85);
    if (picked != null && mounted) setState(() => _photos.add(File(picked.path)));
  }

  void _next() {
    if (_page == 0 && _photos.isEmpty) {
      setState(() => _error = '请至少上传一张照片');
      return;
    }
    setState(() => _error = null);
    if (_page < 2) {
      setState(() => _page++);
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_page > 0) {
      setState(() { _page--; _error = null; });
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic);
    }
  }

  Future<void> _finish() async {
    setState(() { _uploading = true; _error = null; });
    try {
      for (final p in _photos) {
        try { await ref.read(uploadRepositoryProvider).uploadAvatar(p); } catch (_) {}
      }
      await ref.read(profileRepositoryProvider).updateProfile(
        bio: _bioCtrl.text.trim(),
        jobTitle: _jobCtrl.text.trim(),
        lookingFor: _lookingFor,
        height: int.tryParse(_heightCtrl.text.trim()),
        education: _education,
      );
      await ref.read(profileRepositoryProvider).completeOnboarding();
      ref.invalidate(currentUserProvider);
      if (mounted) context.go('/discover');
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '保存失败，请重试');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const pink = Color(0xFFFF4D88);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ---- 顶栏：返回 + 步骤指示 ----
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
              child: Row(
                children: [
                  _page > 0
                      ? IconButton(
                          onPressed: _back,
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: cs.onSurface))
                      : const SizedBox(width: 48),
                  const SizedBox(width: 8),
                  ...List.generate(3, (i) => Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1.5),
                        color: i <= _page ? pink : cs.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ---- 标题 ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Row(
                  key: ValueKey(_page),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 步骤数字 -- 毛玻璃圆形
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pink.withValues(alpha: 0.15),
                        border: Border.all(
                          color: pink.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${_page + 1}',
                          style: const TextStyle(
                            color: Color(0xFFFF4D88),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // 标题+副标题
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            const ['添加照片', '介绍自己', '想遇见谁？'][_page],
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w800,
                                color: cs.onSurface, height: 1.15, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            const [
                              '好照片让匹配率翻倍',
                              '真实的你最有魅力',
                              '最后一步就完成了',
                            ][_page],
                            style: TextStyle(
                                fontSize: 15, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ---- 内容 ----
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _step1Photos(cs, pink),
                  _step2Bio(cs, pink),
                  _step3Preference(cs, pink),
                ],
              ),
            ),

            // ---- 错误 ----
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Text(_error!,
                    style: TextStyle(color: cs.error, fontSize: 13)),
              ),

            // ---- 底部按钮 ----
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 8, 24, MediaQuery.of(context).padding.bottom + 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _uploading ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pink,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: pink.withValues(alpha: 0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _uploading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_page < 2 ? '继续' : '开始探索',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  Step 1 — 照片（2行3列网格，第一格最大）
  // ============================================================
  Widget _step1Photos(ColorScheme cs, Color pink) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spacing = 10.0;
          final colW = (constraints.maxWidth - spacing * 2) / 3;
          final bigH = colW * 2 + spacing; // 2行高

          return SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 主照片（2x2）
                    _photoSlot(0, bigH, colW * 2 + spacing, cs, pink, radius: 20),
                    SizedBox(width: spacing),
                    // 右侧2小格
                    Column(
                      children: [
                        _photoSlot(1, colW, colW, cs, pink),
                        SizedBox(height: spacing),
                        _photoSlot(2, colW, colW, cs, pink),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                // 底部3小格
                Row(
                  children: [
                    _photoSlot(3, colW, colW, cs, pink),
                    SizedBox(width: spacing),
                    _photoSlot(4, colW, colW, cs, pink),
                    SizedBox(width: spacing),
                    _photoSlot(5, colW, colW, cs, pink),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '添加${6 - _photos.length}张照片可提升匹配率',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _photoSlot(int idx, double h, double w, ColorScheme cs, Color pink,
      {double radius = 14}) {
    final hasPhoto = idx < _photos.length;
    return GestureDetector(
      onTap: hasPhoto ? null : _pickPhoto,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: hasPhoto ? Colors.transparent : cs.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: hasPhoto
            ? ClipRRect(
                borderRadius: BorderRadius.circular(radius - 1),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_photos[idx], fit: BoxFit.cover),
                    // 删除
                    Positioned(
                      top: 6, right: 6,
                      child: GestureDetector(
                        onTap: () => setState(() => _photos.removeAt(idx)),
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                    // 主照片标
                    if (idx == 0)
                      Positioned(
                        bottom: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: pink,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('主照片',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              )
            : Center(
                child: Icon(
                  idx == 0 ? Icons.person_rounded : Icons.add_rounded,
                  size: idx == 0 ? 48 : 28,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                ),
              ),
      ),
    );
  }

  // ============================================================
  //  Step 2 — 资料
  // ============================================================
  Widget _step2Bio(ColorScheme cs, Color pink) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio
          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: '写几句介绍自己...',
              counterText: '',
              filled: true,
              fillColor: cs.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 职业 + 身高
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _jobCtrl,
                  decoration: InputDecoration(
                    hintText: '你的职业',
                    filled: true,
                    fillColor: cs.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _heightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '身高cm',
                    filled: true,
                    fillColor: cs.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 学历 chips
          Text('学历',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['高中', '本科', '硕士', '博士'].map((e) {
              final sel = _education == e;
              return GestureDetector(
                onTap: () => setState(() => _education = sel ? null : e),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? pink : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(e,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? Colors.white : cs.onSurface,
                      )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  Step 3 — 偏好
  // ============================================================
  Widget _step3Preference(ColorScheme cs, Color pink) {
    final opts = [
      ('everyone', '所有人'),
      ('female', '女生'),
      ('male', '男生'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: opts.map((o) {
          final sel = _lookingFor == o.$1;
          return GestureDetector(
            onTap: () => setState(() => _lookingFor = o.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: sel ? pink : cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(o.$2,
                      style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : cs.onSurface,
                      )),
                  const Spacer(),
                  if (sel)
                    const Icon(Icons.check_rounded,
                        color: Colors.white, size: 22),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
