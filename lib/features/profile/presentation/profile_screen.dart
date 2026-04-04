import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/domain/user_profile.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/upload_repository.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../../core/errors/app_exception.dart';

/// 资料页 - 升级版UI
/// SliverAppBar视差 + 照片滑动 + 新字段编辑
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(currentUserProvider);
    return Scaffold(
      
      body: profileState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF4D88))),
        error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.wifi_off, size: 48, color: Theme.of(context).colorScheme.error), const SizedBox(height: 12), Text('网络开小差了', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))])),
        data: (user) => _ProfileContent(user: user),
      ),
    );
  }
}

class _ProfileContent extends ConsumerStatefulWidget {
  final UserProfile user;
  const _ProfileContent({required this.user});

  @override
  ConsumerState<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<_ProfileContent> {
  bool _editing = false;
  late TextEditingController _bioCtrl;
  late TextEditingController _jobCtrl;
  late TextEditingController _cityCtrl;
  bool _saving = false;
  bool _uploading = false;
  bool _deleting = false;

  // 新字段
  int? _height;
  String? _education;
  String? _zodiac;
  String? _smoking;
  String? _drinking;

  // 照片轮播
  int _headerPhotoIndex = 0;

  // 常量选项
  static const _educationOptions = ['高中', '大专', '本科', '硕士', '博士', '其他'];
  static const _zodiacOptions = [
    '白羊座', '金牛座', '双子座', '巨蟹座', '狮子座', '处女座',
    '天秤座', '天蝎座', '射手座', '摩羯座', '水瓶座', '双鱼座'
  ];
  static const _smokingOptions = ['从不', '偶尔', '经常'];
  static const _drinkingOptions = ['从不', '社交场合', '经常'];

  @override
  void initState() {
    super.initState();
    _bioCtrl = TextEditingController(text: widget.user.bio ?? '');
    _jobCtrl = TextEditingController(text: widget.user.jobTitle ?? '');
    _cityCtrl = TextEditingController(text: widget.user.city ?? '');
    _height = widget.user.height;
    _education = widget.user.education;
    _zodiac = widget.user.zodiac;
    _smoking = widget.user.smoking;
    _drinking = widget.user.drinking;
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _jobCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
        bio: _bioCtrl.text.trim(),
        jobTitle: _jobCtrl.text.trim(),
        lookingFor: widget.user.lookingFor,
        height: _height,
        education: _education,
        zodiac: _zodiac,
        city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
        smoking: _smoking,
        drinking: _drinking,
      );
      ref.invalidate(currentUserProvider);
      setState(() => _editing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('资料已更新')));
      }
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addPhoto() async {
    if (widget.user.avatarUrls.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('最多只能上传6张照片')));
      return;
    }
    setState(() => _uploading = true);
    try {
      await ref.read(uploadRepositoryProvider).pickAndUpload();
      ref.invalidate(currentUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('照片已添加')));
      }
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deletePhoto(int index) async {
    if (widget.user.avatarUrls.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('至少需要保留一张照片')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('删除照片'),
        content: const Text('确定要删除这张照片吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('删除', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(profileRepositoryProvider).deleteAvatar(index);
      ref.invalidate(currentUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('照片已删除')));
      }
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _uploadAvatar() async {
    await _addPhoto();
  }

  /// 拖拽重排照片
  Future<void> _reorderPhotos(List<String> newUrls) async {
    try {
      await ref.read(profileRepositoryProvider).reorderAvatars(newUrls);
      ref.invalidate(currentUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('照片顺序已更新')));
      }
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final photos = user.avatarUrls;

    // 删除照片后 _headerPhotoIndex 可能越界，需要修正
    if (_headerPhotoIndex >= photos.length) {
      _headerPhotoIndex = photos.isEmpty ? 0 : photos.length - 1;
    }

    return CustomScrollView(
      slivers: [
        // 顶部大图 AppBar + 视差 + 照片轮播
        SliverAppBar(
          expandedHeight: 360,
          pinned: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            IconButton(
              icon: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha:0.3),
                ),
                child: Icon(_editing ? Icons.close : Icons.edit,
                    color: Colors.white, size: 18),
              ),
              onPressed: () => setState(() => _editing = !_editing),
            ),
            IconButton(
              icon: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha:0.3),
                ),
                child: const Icon(Icons.settings_outlined,
                    color: Colors.white, size: 18),
              ),
              onPressed: () => context.go('/settings'),
            ),
            const SizedBox(width: 4),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // 照片轮播（视差效果）
                if (photos.isNotEmpty)
                  PageView.builder(
                    itemCount: photos.length,
                    onPageChanged: (i) => setState(() => _headerPhotoIndex = i),
                    itemBuilder: (_, i) => CachedNetworkImage(
                      memCacheWidth: 800,
                      imageUrl: photos[i],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0] : '?',
                        style: const TextStyle(
                            fontSize: 80,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                // 底部渐变
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha:0.5),
                        ],
                      ),
                    ),
                  ),
                ),

                // 照片指示器小点
                if (photos.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(photos.length, (i) {
                        return Container(
                          width: i == _headerPhotoIndex ? 20 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: i == _headerPhotoIndex
                                ? Colors.white
                                : Colors.white.withValues(alpha:0.4),
                          ),
                        );
                      }),
                    ),
                  ),

                // 编辑模式下的上传按钮
                if (_editing)
                  Positioned(
                    bottom: 40,
                    right: 16,
                    child: GestureDetector(
                      onTap: _uploadAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF4D88),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4D88).withValues(alpha:0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _uploading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.camera_alt,
                                size: 20, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 基本信息卡片：名字、年龄、城市、职业
                _SectionCard(
                  title: '基本信息',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(user.name,
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface)),
                          if (user.age != null) ...[
                            const SizedBox(width: 8),
                            Text('${user.age}岁',
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(user.email,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                      const SizedBox(height: 10),
                      // 城市和职业
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (_editing) ...[
                            SizedBox(
                              width: 140,
                              child: TextField(
                                controller: _cityCtrl,
                                decoration: _tagInputDeco('城市', Icons.location_on_outlined),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: TextField(
                                controller: _jobCtrl,
                                decoration: _tagInputDeco('职业', Icons.work_outline),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ] else ...[
                            if (user.city?.isNotEmpty == true)
                              _DetailTag(
                                  icon: Icons.location_on_outlined,
                                  text: user.city!),
                            if (user.jobTitle?.isNotEmpty == true)
                              _DetailTag(
                                  icon: Icons.work_outline,
                                  text: user.jobTitle!),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 详细信息卡片：身高、学历、星座、吸烟、饮酒
                _SectionCard(
                  title: '详细信息',
                  child: _editing
                      ? _buildEditableDetails()
                      : _buildDetailTags(user),
                ),

                const SizedBox(height: 12),

                // 照片管理
                _SectionCard(
                  title: '我的照片（${user.avatarUrls.length}/6）',
                  child: _PhotoGrid(
                    avatarUrls: user.avatarUrls,
                    editing: _editing,
                    uploading: _uploading,
                    deleting: _deleting,
                    onAdd: _addPhoto,
                    onDelete: _deletePhoto,
                    onReorder: _reorderPhotos,
                  ),
                ),

                const SizedBox(height: 12),

                // 关于我
                _SectionCard(
                  title: '关于我',
                  child: _editing
                      ? TextField(
                          controller: _bioCtrl,
                          maxLines: 4,
                          maxLength: 200,
                          decoration: const InputDecoration(
                              hintText: '介绍一下自己...',
                              border: InputBorder.none,
                              counterText: ''),
                        )
                      : Text(
                          user.bio?.isNotEmpty == true
                              ? user.bio!
                              : '写点什么，让别人认识真实的你',
                          style: TextStyle(
                              color: user.bio?.isNotEmpty == true
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.6,
                              fontSize: 15)),
                ),

                // 兴趣标签
                if (user.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: '兴趣标签',
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: user.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4D88).withValues(alpha:0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(tag,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      )).toList(),
                    ),
                  ),
                ],

                // 保存按钮
                if (_editing) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
                        ),
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4D88).withValues(alpha:0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 22, width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('保存资料',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1)),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 展示模式下的详细信息标签
  Widget _buildDetailTags(UserProfile user) {
    final tags = <Widget>[];
    if (user.height != null) {
      tags.add(_DetailTag(icon: Icons.straighten, text: '${user.height}cm'));
    }
    if (user.education?.isNotEmpty == true) {
      tags.add(_DetailTag(icon: Icons.school_outlined, text: user.education!));
    }
    if (user.zodiac?.isNotEmpty == true) {
      tags.add(_DetailTag(icon: Icons.auto_awesome, text: user.zodiac!));
    }
    if (user.smoking?.isNotEmpty == true) {
      tags.add(_DetailTag(icon: Icons.smoking_rooms, text: '吸烟: ${user.smoking!}'));
    }
    if (user.drinking?.isNotEmpty == true) {
      tags.add(_DetailTag(icon: Icons.local_bar, text: '饮酒: ${user.drinking!}'));
    }
    if (tags.isEmpty) {
      return Text('点击编辑添加详细信息',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14));
    }
    return Wrap(spacing: 8, runSpacing: 8, children: tags);
  }

  /// 编辑模式下的详细信息
  Widget _buildEditableDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 身高
        _EditRow(
          label: '身高',
          icon: Icons.straighten,
          child: SizedBox(
            width: 120,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '如 175',
                suffixText: 'cm',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                isDense: true,
              ),
              controller: TextEditingController(
                  text: _height?.toString() ?? ''),
              onChanged: (v) => _height = int.tryParse(v),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 学历
        _EditRow(
          label: '学历',
          icon: Icons.school_outlined,
          child: _DropdownSelector(
            value: _education,
            options: _educationOptions,
            hint: '选择学历',
            onChanged: (v) => setState(() => _education = v),
          ),
        ),
        const SizedBox(height: 14),

        // 星座
        _EditRow(
          label: '星座',
          icon: Icons.auto_awesome,
          child: _DropdownSelector(
            value: _zodiac,
            options: _zodiacOptions,
            hint: '选择星座',
            onChanged: (v) => setState(() => _zodiac = v),
          ),
        ),
        const SizedBox(height: 14),

        // 吸烟
        _EditRow(
          label: '吸烟',
          icon: Icons.smoking_rooms,
          child: _DropdownSelector(
            value: _smoking,
            options: _smokingOptions,
            hint: '选择',
            onChanged: (v) => setState(() => _smoking = v),
          ),
        ),
        const SizedBox(height: 14),

        // 饮酒
        _EditRow(
          label: '饮酒',
          icon: Icons.local_bar,
          child: _DropdownSelector(
            value: _drinking,
            options: _drinkingOptions,
            hint: '选择',
            onChanged: (v) => setState(() => _drinking = v),
          ),
        ),
      ],
    );
  }

  InputDecoration _tagInputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFFFF4D88)),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    );
  }
}

/// 编辑行组件
class _EditRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  const _EditRow({required this.label, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFFF4D88)),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface)),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}

/// 下拉选择器
class _DropdownSelector extends StatelessWidget {
  final String? value;
  final List<String> options;
  final String hint;
  final ValueChanged<String?> onChanged;

  const _DropdownSelector({
    required this.value,
    required this.options,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value != null && options.contains(value) ? value : null,
          hint: Text(hint,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
          items: options.map((o) => DropdownMenuItem(
            value: o,
            child: Text(o, style: const TextStyle(fontSize: 14)),
          )).toList(),
          onChanged: onChanged,
          icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
          isDense: true,
        ),
      ),
    );
  }
}

/// 详细信息标签
class _DetailTag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF4D88).withValues(alpha:0.08),
            const Color(0xFFFF8A5C).withValues(alpha:0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF4D88).withValues(alpha:0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFFFF4D88)),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFFF4D88))),
        ],
      ),
    );
  }
}

/// 照片管理网格（编辑模式支持拖拽重排）
class _PhotoGrid extends StatefulWidget {
  final List<String> avatarUrls;
  final bool editing;
  final bool uploading;
  final bool deleting;
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;
  final ValueChanged<List<String>> onReorder;

  const _PhotoGrid({
    required this.avatarUrls,
    required this.editing,
    required this.uploading,
    required this.deleting,
    required this.onAdd,
    required this.onDelete,
    required this.onReorder,
  });

  @override
  State<_PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<_PhotoGrid> {
  late List<String> _urls;
  int? _dragIndex;

  @override
  void initState() {
    super.initState();
    _urls = List.from(widget.avatarUrls);
  }

  @override
  void didUpdateWidget(covariant _PhotoGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrls != widget.avatarUrls) {
      _urls = List.from(widget.avatarUrls);
    }
  }

  /// 构建单张照片卡片
  Widget _buildPhotoCard(String url, int index, {bool isDragging = false}) {
    return Opacity(
      opacity: isDragging ? 0.4 : 1.0,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha:0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: 400,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.broken_image, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D88).withValues(alpha:0.85),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Text('主照片',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          if (widget.editing) ...[
            // 删除按钮
            Positioned(
              top: 4, right: 4,
              child: GestureDetector(
                onTap: widget.deleting ? null : () => widget.onDelete(index),
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha:0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 14, color: Colors.white),
                ),
              ),
            ),
            // 拖拽提示图标
            Positioned(
              bottom: index == 0 ? 26 : 4, left: 4,
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.drag_indicator,
                    size: 14, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final showAddBtn = widget.editing && _urls.length < 6;
    final itemCount = _urls.length + (showAddBtn ? 1 : 0);

    // 编辑模式：使用 Wrap + LongPressDraggable + DragTarget 实现拖拽网格
    if (widget.editing) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(itemCount, (index) {
          // 添加照片按钮
          if (index == _urls.length && showAddBtn) {
            return SizedBox(
              width: (mq.size.width - 40 - 18 * 2 - 8 * 2) / 3,
              height: (mq.size.width - 40 - 18 * 2 - 8 * 2) / 3 / 0.75,
              child: GestureDetector(
                onTap: widget.uploading ? null : widget.onAdd,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF4D88).withValues(alpha:0.4),
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: widget.uploading
                      ? const Center(
                          child: SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFF4D88),
                            ),
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 28, color: Color(0xFFFF4D88)),
                            SizedBox(height: 4),
                            Text('添加照片',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFFFF4D88))),
                          ],
                        ),
                ),
              ),
            );
          }

          final url = _urls[index];
          final cardWidth = (mq.size.width - 40 - 18 * 2 - 8 * 2) / 3;
          final cardHeight = cardWidth / 0.75;

          return DragTarget<int>(
            onWillAcceptWithDetails: (details) => details.data != index,
            onAcceptWithDetails: (details) {
              final fromIndex = details.data;
              setState(() {
                final item = _urls.removeAt(fromIndex);
                _urls.insert(index, item);
                _dragIndex = null;
              });
              // 调用后端重排API
              widget.onReorder(List.from(_urls));
            },
            builder: (context, candidateData, rejectedData) {
              final isTarget = candidateData.isNotEmpty;
              return LongPressDraggable<int>(
                data: index,
                delay: const Duration(milliseconds: 200),
                onDragStarted: () => setState(() => _dragIndex = index),
                onDragEnd: (_) => setState(() => _dragIndex = null),
                onDraggableCanceled: (_, __) => setState(() => _dragIndex = null),
                feedback: Material(
                  color: Colors.transparent,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: _buildPhotoCard(url, index),
                  ),
                ),
                childWhenDragging: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF4D88).withValues(alpha:0.3),
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: cardWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: isTarget
                        ? Border.all(color: const Color(0xFFFF4D88), width: 2)
                        : null,
                  ),
                  child: _buildPhotoCard(url, index,
                      isDragging: _dragIndex == index),
                ),
              );
            },
          );
        }),
      );
    }

    // 非编辑模式：普通网格
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: _urls.length,
      itemBuilder: (context, index) {
        if (index >= _urls.length) return const SizedBox.shrink();
        return _buildPhotoCard(_urls[index], index);
      },
    );
  }
}

/// 区块卡片
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha:0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D88),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF4D88),
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
