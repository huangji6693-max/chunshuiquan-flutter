import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/upload_repository.dart';

/// Onboarding — 沉浸式全屏引导
/// 对标 Tinder/Bumble：大面积留白+渐变背景+极简交互
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // Step 1
  final List<File> _photos = [];
  // Step 2
  final _bioCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String? _education;
  // Step 3
  String _lookingFor = 'everyone';

  bool _uploading = false;
  String? _error;

  static const _educationOptions = ['高中', '本科', '硕士', '博士'];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _bioCtrl.dispose();
    _jobCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1080, imageQuality: 85);
    if (picked != null && mounted) {
      setState(() => _photos.add(File(picked.path)));
    }
  }

  Future<void> _finish() async {
    setState(() { _uploading = true; _error = null; });
    try {
      // 上传照片
      for (final photo in _photos) {
        try { await ref.read(uploadRepositoryProvider).uploadAvatar(photo); } catch (_) {}
      }
      // 更新资料
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '保存失败，请重试');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _next() {
    if (_page == 0 && _photos.isEmpty) {
      setState(() => _error = '请至少上传一张照片');
      return;
    }
    setState(() => _error = null);
    if (_page < 2) {
      setState(() => _page++);
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_page > 0) {
      setState(() { _page--; _error = null; });
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.surface,
              cs.surface,
              const Color(0xFFFF4D88).withValues(alpha: 0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部：返回 + 进度条
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    if (_page > 0)
                      IconButton(
                        onPressed: _back,
                        icon: Icon(Icons.arrow_back_ios_rounded, size: 20, color: cs.onSurface),
                      )
                    else
                      const SizedBox(width: 48),
                    const SizedBox(width: 8),
                    // 进度条
                    ...List.generate(3, (i) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i <= _page
                              ? const Color(0xFFFF4D88)
                              : cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 步骤标题——大字、居左、有力量
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      ['展示你的魅力', '让大家认识你', '你想遇见谁'][_page],
                      key: ValueKey(_page),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ['上传至少1张照片', '完善你的个人档案', '选择你感兴趣的'][_page],
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant, height: 1.4),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 内容区
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPhotoStep(cs),
                    _buildBioStep(cs),
                    _buildPreferenceStep(cs),
                  ],
                ),
              ),

              // 错误
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
                ),

              // 底部按钮
              Padding(
                padding: EdgeInsets.fromLTRB(28, 12, 28, MediaQuery.of(context).padding.bottom + 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF4D88), Color(0xFFFF7043)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4D88).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _uploading ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _uploading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(
                              _page < 2 ? '继续' : '开始探索',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== Step 1: 照片 ======
  Widget _buildPhotoStep(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          // 主照片（大）
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: _photos.isEmpty ? _pickPhoto : null,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _photos.isEmpty
                        ? const Color(0xFFFF4D88).withValues(alpha: 0.3)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: _photos.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFF4D88).withValues(alpha: 0.1),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                color: Color(0xFFFF4D88), size: 32),
                          ),
                          const SizedBox(height: 16),
                          Text('点击添加主照片',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w500)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_photos[0], fit: BoxFit.cover),
                            // 删除按钮
                            Positioned(
                              top: 12, right: 12,
                              child: GestureDetector(
                                onTap: () => setState(() => _photos.removeAt(0)),
                                child: Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 提示文字
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '上传3张以上照片，匹配率提升200% \u{1F525}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          // 小照片（横排）
          SizedBox(
            height: 80,
            child: Row(
              children: List.generate(5, (i) {
                final photoIdx = i + 1;
                final hasPhoto = photoIdx < _photos.length;
                return Expanded(
                  child: GestureDetector(
                    onTap: hasPhoto
                        ? () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('删除照片？'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      setState(() => _photos.removeAt(photoIdx));
                                    },
                                    child: const Text('删除',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            )
                        : (photoIdx <= _photos.length ? _pickPhoto : null),
                    child: Container(
                      margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: photoIdx <= _photos.length
                            ? Border.all(color: const Color(0xFFFF4D88).withValues(alpha: 0.2))
                            : null,
                      ),
                      child: hasPhoto
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.file(_photos[photoIdx], fit: BoxFit.cover),
                            )
                          : photoIdx <= _photos.length
                              ? Icon(Icons.add_rounded, color: cs.onSurfaceVariant, size: 22)
                              : null,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ====== Step 2: 资料 ======
  Widget _buildBioStep(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          _inputField(
            controller: _bioCtrl,
            label: '关于你',
            hint: '写几句介绍自己...',
            maxLines: 3,
            maxLength: 200,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _inputField(controller: _jobCtrl, label: '职业', hint: '你的职业')),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: _inputField(controller: _heightCtrl, label: '身高', hint: 'cm', keyboardType: TextInputType.number),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 学历选择——用胶囊chips代替dropdown
          Align(
            alignment: Alignment.centerLeft,
            child: Text('学历', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _educationOptions.map((e) {
              final selected = _education == e;
              return GestureDetector(
                onTap: () => setState(() => _education = selected ? null : e),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFF4D88).withValues(alpha: 0.12)
                        : Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? const Color(0xFFFF4D88) : Theme.of(context).colorScheme.outlineVariant,
                      width: selected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(e, style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? const Color(0xFFFF4D88) : Theme.of(context).colorScheme.onSurface,
                  )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
          ),
        ),
      ],
    );
  }

  // ====== Step 3: 偏好 ======
  Widget _buildPreferenceStep(ColorScheme cs) {
    final options = [
      ('everyone', '所有人', '不限性别'),
      ('female', '女生', '只看女生'),
      ('male', '男生', '只看男生'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: options.map((opt) {
          final selected = _lookingFor == opt.$1;
          return GestureDetector(
            onTap: () => setState(() => _lookingFor = opt.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFF4D88).withValues(alpha: 0.08)
                    : cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? const Color(0xFFFF4D88) : cs.outlineVariant.withValues(alpha: 0.3),
                  width: selected ? 2 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opt.$2, style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: selected ? const Color(0xFFFF4D88) : cs.onSurface,
                        )),
                        const SizedBox(height: 2),
                        Text(opt.$3, style: TextStyle(
                          fontSize: 13, color: cs.onSurfaceVariant,
                        )),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? const Color(0xFFFF4D88) : Colors.transparent,
                      border: Border.all(
                        color: selected ? const Color(0xFFFF4D88) : cs.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : null,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
