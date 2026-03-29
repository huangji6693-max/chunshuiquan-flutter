import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../auth/data/auth_repository.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // 资料字段
  final _bioCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  String _lookingFor = 'everyone';
  final List<File> _photos = [];
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _bioCtrl.dispose();
    _jobCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _photos.add(File(picked.path)));
    }
  }

  Future<void> _finish() async {
    setState(() { _uploading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      final authRepo = ref.read(authRepositoryProvider);

      // 更新资料
      await dio.put('/api/users/profile', data: {
        'bio': _bioCtrl.text.trim(),
        'jobTitle': _jobCtrl.text.trim(),
        'lookingFor': _lookingFor,
      });

      // 上传头像（简化：直接用本地路径作为占位，真实场景需上传到 CDN）
      // 这里演示流程，实际需要 multipart upload 到 S3/Cloudinary
      if (_photos.isNotEmpty) {
        // TODO: 上传到 CDN，获取 URL 后调用 POST /api/users/avatar
        // 暂时跳过，后续接 Cloudinary
      }

      if (mounted) context.go('/discover');
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '保存失败，请重试');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 进度指示器
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _page ? primary : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _PhotoPage(
                    photos: _photos,
                    onAdd: _pickPhoto,
                    onRemove: (i) => setState(() => _photos.removeAt(i)),
                  ),
                  _BioPage(bioCtrl: _bioCtrl, jobCtrl: _jobCtrl),
                  _PreferencePage(
                    lookingFor: _lookingFor,
                    onChanged: (v) => setState(() => _lookingFor = v),
                  ),
                ],
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: _uploading ? null : () {
                  if (_page < 2) {
                    setState(() => _page++);
                    _pageCtrl.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _finish();
                  }
                },
                child: _uploading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_page < 2 ? '下一步' : '开始使用 🎉'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPage extends StatelessWidget {
  final List<File> photos;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  const _PhotoPage({required this.photos, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('上传你的照片', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('至少上传1张，展示真实的你', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
              ),
              itemCount: photos.length < 6 ? photos.length + 1 : photos.length,
              itemBuilder: (ctx, i) {
                if (i == photos.length && photos.length < 6) {
                  return GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey),
                    ),
                  );
                }
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(photos[i], fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4, right: 4,
                      child: GestureDetector(
                        onTap: () => onRemove(i),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BioPage extends StatelessWidget {
  final TextEditingController bioCtrl, jobCtrl;
  const _BioPage({required this.bioCtrl, required this.jobCtrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('介绍一下自己', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('让别人更了解你', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          TextField(
            controller: bioCtrl,
            decoration: const InputDecoration(
              labelText: '个人简介',
              hintText: '用几句话描述自己...',
            ),
            maxLines: 4,
            maxLength: 200,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: jobCtrl,
            decoration: const InputDecoration(
              labelText: '职业（可选）',
              hintText: '产品经理、设计师...',
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferencePage extends StatelessWidget {
  final String lookingFor;
  final void Function(String) onChanged;
  const _PreferencePage({required this.lookingFor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final options = [
      ('everyone', '所有人', Icons.people),
      ('male', '男生', Icons.male),
      ('female', '女生', Icons.female),
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('你想遇见谁？', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('可以随时在设置里修改', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          ...options.map((opt) => GestureDetector(
            onTap: () => onChanged(opt.$1),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lookingFor == opt.$1 ? primary.withOpacity(0.1) : Colors.white,
                border: Border.all(color: lookingFor == opt.$1 ? primary : Colors.grey[300]!),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Icon(opt.$3, color: lookingFor == opt.$1 ? primary : Colors.grey),
                const SizedBox(width: 12),
                Text(opt.$2, style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: lookingFor == opt.$1 ? primary : Colors.black87,
                )),
                const Spacer(),
                if (lookingFor == opt.$1) Icon(Icons.check_circle, color: primary),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}
