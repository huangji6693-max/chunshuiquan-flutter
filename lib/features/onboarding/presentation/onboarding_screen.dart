import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/upload_repository.dart';

/// Onboarding流程页面
/// 3步：照片上传 → 信息填写 → 偏好设置
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // 步骤1：照片
  final List<File> _photos = [];

  // 步骤2：资料字段
  final _bioCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String? _education;
  String? _zodiac;

  // 步骤3：偏好
  String _lookingFor = 'everyone';

  bool _uploading = false;
  String? _error;

  // 步骤标题和副标题
  static const _stepTitles = [
    '展示你的魅力',
    '让大家认识你',
    '你想遇见谁',
  ];
  static const _stepSubtitles = [
    '上传至少1张照片，最多6张',
    '完善个人信息',
    '设置你的偏好',
  ];

  // 学历选项
  static const _educationOptions = ['高中', '本科', '硕士', '博士'];

  // 星座选项
  static const _zodiacOptions = [
    '白羊座', '金牛座', '双子座', '巨蟹座', '狮子座', '处女座',
    '天秤座', '天蝎座', '射手座', '摩羯座', '水瓶座', '双鱼座',
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _bioCtrl.dispose();
    _jobCtrl.dispose();
    _heightCtrl.dispose();
    _cityCtrl.dispose();
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

  Future<void> _uploadPhotos() async {
    for (final photo in _photos) {
      try {
        await ref.read(uploadRepositoryProvider).uploadAvatar(photo);
      } catch (_) {
        // 上传失败继续，不阻断 onboarding 流程
      }
    }
  }

  Future<void> _finish() async {
    setState(() { _uploading = true; _error = null; });
    try {
      await _uploadPhotos();

      // 解析身高
      int? height;
      if (_heightCtrl.text.trim().isNotEmpty) {
        height = int.tryParse(_heightCtrl.text.trim());
      }

      // 更新用户资料
      await ref.read(profileRepositoryProvider).updateProfile(
        bio: _bioCtrl.text.trim(),
        jobTitle: _jobCtrl.text.trim(),
        lookingFor: _lookingFor,
        height: height,
        education: _education,
        zodiac: _zodiac,
        city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
      );

      // 调用完成onboarding接口
      await ref.read(profileRepositoryProvider).completeOnboarding();

      // 刷新用户信息
      ref.invalidate(currentUserProvider);

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
    const pink = Color(0xFFFF4D88);

    return Scaffold(
      
      body: SafeArea(
        child: Column(
          children: [
            // 分段式彩色进度条
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: i <= _page
                          ? const LinearGradient(
                              colors: [Color(0xFFFF4D88), Color(0xFFFF7043)],
                            )
                          : null,
                      color: i <= _page ? null : Colors.grey[200],
                    ),
                  ),
                )),
              ),
            ),

            // 步骤标题和副标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stepTitles[_page],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _stepSubtitles[_page],
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 页面内容
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
                  _BioPage(
                    bioCtrl: _bioCtrl,
                    jobCtrl: _jobCtrl,
                    heightCtrl: _heightCtrl,
                    cityCtrl: _cityCtrl,
                    education: _education,
                    zodiac: _zodiac,
                    educationOptions: _educationOptions,
                    zodiacOptions: _zodiacOptions,
                    onEducationChanged: (v) => setState(() => _education = v),
                    onZodiacChanged: (v) => setState(() => _zodiac = v),
                  ),
                  _PreferencePage(
                    lookingFor: _lookingFor,
                    onChanged: (v) => setState(() => _lookingFor = v),
                  ),
                ],
              ),
            ),

            // 错误提示
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),
                ),
              ),

            // 底部按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  if (_page > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _uploading ? null : () {
                          setState(() { _page--; _error = null; });
                          _pageCtrl.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: pink,
                          side: const BorderSide(color: pink),
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('上一步'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: _page > 0 ? 2 : 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4D88), Color(0xFFFF7043)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4D88).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _uploading ? null : () {
                          if (_page == 0 && _photos.isEmpty) {
                            setState(() => _error = '请至少上传一张照片');
                            return;
                          }
                          setState(() => _error = null);
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _uploading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white,
                                ),
                              )
                            : Text(
                                _page < 2 ? '继续' : '开启春水圈',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 步骤1：照片上传页面
class _PhotoPage extends StatelessWidget {
  final List<File> photos;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  const _PhotoPage({required this.photos, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
        ),
        itemCount: photos.length < 6 ? photos.length + 1 : photos.length,
        itemBuilder: (ctx, i) {
          // 添加按钮
          if (i == photos.length && photos.length < 6) {
            return GestureDetector(
              onTap: onAdd,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D88).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF4D88).withOpacity(0.3),
                    width: 1.5,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 32,
                      color: const Color(0xFFFF4D88).withOpacity(0.6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '添加',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFFF4D88).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          // 已选照片
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(photos[i], fit: BoxFit.cover),
              ),
              // 第一张标记为主照片
              if (i == 0)
                Positioned(
                  bottom: 6, left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D88),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '主照片',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              // 删除按钮
              Positioned(
                top: 4, right: 4,
                child: GestureDetector(
                  onTap: () => onRemove(i),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 步骤2：个人信息填写页面（含新增字段）
class _BioPage extends StatelessWidget {
  final TextEditingController bioCtrl, jobCtrl, heightCtrl, cityCtrl;
  final String? education;
  final String? zodiac;
  final List<String> educationOptions;
  final List<String> zodiacOptions;
  final void Function(String?) onEducationChanged;
  final void Function(String?) onZodiacChanged;

  const _BioPage({
    required this.bioCtrl,
    required this.jobCtrl,
    required this.heightCtrl,
    required this.cityCtrl,
    required this.education,
    required this.zodiac,
    required this.educationOptions,
    required this.zodiacOptions,
    required this.onEducationChanged,
    required this.onZodiacChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 个人简介
          TextField(
            controller: bioCtrl,
            decoration: const InputDecoration(
              labelText: '个人简介',
              hintText: '用几句话描述自己...',
            ),
            maxLines: 3,
            maxLength: 200,
          ),
          const SizedBox(height: 12),

          // 职业
          TextField(
            controller: jobCtrl,
            decoration: const InputDecoration(
              labelText: '职业（可选）',
              hintText: '产品经理、设计师...',
            ),
          ),
          const SizedBox(height: 16),

          // 身高
          TextField(
            controller: heightCtrl,
            decoration: const InputDecoration(
              labelText: '身高',
              hintText: '身高(cm)',
              suffixText: 'cm',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // 学历选择
          DropdownButtonFormField<String>(
            value: education,
            decoration: const InputDecoration(
              labelText: '学历',
            ),
            hint: const Text('选择学历'),
            items: educationOptions.map((e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            )).toList(),
            onChanged: onEducationChanged,
          ),
          const SizedBox(height: 16),

          // 星座选择
          DropdownButtonFormField<String>(
            value: zodiac,
            decoration: const InputDecoration(
              labelText: '星座',
            ),
            hint: const Text('选择星座'),
            items: zodiacOptions.map((e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            )).toList(),
            onChanged: onZodiacChanged,
          ),
          const SizedBox(height: 16),

          // 城市
          TextField(
            controller: cityCtrl,
            decoration: const InputDecoration(
              labelText: '城市',
              hintText: '你所在的城市',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// 步骤3：偏好设置页面
class _PreferencePage extends StatelessWidget {
  final String lookingFor;
  final void Function(String) onChanged;
  const _PreferencePage({required this.lookingFor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF4D88);
    final options = [
      ('everyone', '所有人', Icons.people_rounded),
      ('male', '男生', Icons.male_rounded),
      ('female', '女生', Icons.female_rounded),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          ...options.map((opt) => GestureDetector(
            onTap: () => onChanged(opt.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: lookingFor == opt.$1
                    ? const Color(0xFFFF4D88).withOpacity(0.1)
                    : Colors.white,
                border: Border.all(
                  color: lookingFor == opt.$1 ? pink : Colors.grey[300]!,
                  width: lookingFor == opt.$1 ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: lookingFor == opt.$1
                    ? [
                        BoxShadow(
                          color: pink.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lookingFor == opt.$1
                        ? pink.withOpacity(0.1)
                        : Colors.grey[100],
                  ),
                  child: Icon(
                    opt.$3,
                    color: lookingFor == opt.$1 ? pink : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(opt.$2, style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: lookingFor == opt.$1 ? pink : Colors.black87,
                )),
                const Spacer(),
                if (lookingFor == opt.$1)
                  const Icon(Icons.check_circle_rounded, color: pink, size: 24),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}
