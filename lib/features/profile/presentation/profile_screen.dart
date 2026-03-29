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

  Future<void> _uploadAvatar() async {
    setState(() => _uploading = true);
    try {
      await ref.read(uploadRepositoryProvider).pickAndUpload();
      ref.invalidate(currentUserProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 头像已更新')));
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
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
