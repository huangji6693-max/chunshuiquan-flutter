import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_profile.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/upload_repository.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../../core/errors/app_exception.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: profileState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF4D88))),
        error: (e, _) => Center(child: Text('加载失败: $e')),
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
  bool _saving = false;
  bool _uploading = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _bioCtrl = TextEditingController(text: widget.user.bio ?? '');
    _jobCtrl = TextEditingController(text: widget.user.jobTitle ?? '');
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _jobCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
        bio: _bioCtrl.text.trim(),
        jobTitle: _jobCtrl.text.trim(),
        lookingFor: widget.user.lookingFor,
      );
      ref.invalidate(currentUserProvider);
      setState(() => _editing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ 资料已更新')));
      }
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 添加照片：选图 -> 上传Cloudinary -> 保存到后端
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
            const SnackBar(content: Text('✅ 照片已添加')));
      }
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// 删除指定索引的照片
  Future<void> _deletePhoto(int index) async {
    // 至少保留一张照片
    if (widget.user.avatarUrls.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('至少需要保留一张照片')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除照片'),
        content: const Text('确定要删除这张照片吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
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
            const SnackBar(content: Text('✅ 照片已删除')));
      }
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  /// 兼容旧的上传头像方法（用于AppBar区域点击头像）
  Future<void> _uploadAvatar() async {
    await _addPhoto();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return CustomScrollView(
      slivers: [
        // 顶部大图 AppBar
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: const Color(0xFFFF4D88),
          actions: [
            IconButton(
              icon: Icon(_editing ? Icons.close : Icons.edit,
                  color: Colors.white),
              onPressed: () => setState(() => _editing = !_editing),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () => context.push('/settings'),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // 背景渐变
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF4D88), Color(0xFFFF7043)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // 头像
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: _editing ? _uploadAvatar : null,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 16,
                                  )
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 56,
                                backgroundImage: user.firstAvatar.isNotEmpty
                                    ? CachedNetworkImageProvider(
                                        user.firstAvatar)
                                    : null,
                                backgroundColor: Colors.white24,
                                child: user.firstAvatar.isEmpty
                                    ? Text(
                                        user.name.isNotEmpty
                                            ? user.name[0]
                                            : '?',
                                        style: const TextStyle(
                                            fontSize: 40,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700))
                                    : null,
                              ),
                            ),
                            if (_editing)
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _uploading
                                      ? const SizedBox(
                                          width: 14, height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFFFF4D88)))
                                      : const Icon(Icons.camera_alt,
                                          size: 14,
                                          color: Color(0xFFFF4D88)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
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
                // 姓名
                Center(
                  child: Text(user.name,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E))),
                ),
                Center(
                  child: Text(user.email,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 14)),
                ),
                const SizedBox(height: 24),

                // 照片管理网格
                _SectionCard(
                  title: '我的照片（${user.avatarUrls.length}/6）',
                  child: _PhotoGrid(
                    avatarUrls: user.avatarUrls,
                    editing: _editing,
                    uploading: _uploading,
                    deleting: _deleting,
                    onAdd: _addPhoto,
                    onDelete: _deletePhoto,
                  ),
                ),

                const SizedBox(height: 12),

                // Bio 编辑
                _SectionCard(
                  title: '个人简介',
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
                              : '还没有简介，点右上角编辑 ✏️',
                          style: TextStyle(
                              color: user.bio?.isNotEmpty == true
                                  ? Colors.black87
                                  : Colors.grey,
                              height: 1.6)),
                ),

                const SizedBox(height: 12),

                // 职业
                _SectionCard(
                  title: '职业',
                  child: _editing
                      ? TextField(
                          controller: _jobCtrl,
                          decoration: const InputDecoration(
                              hintText: '你的职业...',
                              border: InputBorder.none),
                        )
                      : Text(
                          user.jobTitle?.isNotEmpty == true
                              ? user.jobTitle!
                              : '未填写',
                          style: TextStyle(
                              color: user.jobTitle?.isNotEmpty == true
                                  ? Colors.black87
                                  : Colors.grey)),
                ),

                // 标签
                if (user.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: '兴趣标签',
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: user.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF4D88), Color(0xFFFF7043)],
                          ),
                          borderRadius: BorderRadius.circular(20),
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4D88), Color(0xFFFF7043)],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('保存',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
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
}

/// 照片管理网格组件
/// 显示最多6张照片，支持编辑模式下的删除和添加
/// TODO: 后端实现重排API后，增加长按拖拽重排功能
class _PhotoGrid extends StatelessWidget {
  final List<String> avatarUrls;
  final bool editing;
  final bool uploading;
  final bool deleting;
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;

  const _PhotoGrid({
    required this.avatarUrls,
    required this.editing,
    required this.uploading,
    required this.deleting,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 总共显示的格子数：已有照片 + 添加按钮（编辑模式且未满6张时）
    final showAddBtn = editing && avatarUrls.length < 6;
    final itemCount = avatarUrls.length + (showAddBtn ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // 添加照片按钮
        if (index == avatarUrls.length && showAddBtn) {
          return GestureDetector(
            onTap: uploading ? null : onAdd,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF4D88).withOpacity(0.4),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: uploading
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
          );
        }

        // 照片卡片
        final url = avatarUrls[index];
        return Stack(
          children: [
            // 照片
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
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
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (_, __) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            // 第一张照片的主照片标签
            if (index == 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D88).withOpacity(0.85),
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
            // 编辑模式下的删除按钮
            if (editing)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: deleting ? null : () => onDelete(index),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
