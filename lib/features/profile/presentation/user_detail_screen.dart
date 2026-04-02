import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../discover/domain/user_profile.dart';
import '../../report/report_bottom_sheet.dart' show showReportSheet;

/// 用户详情页 — 查看他人完整资料
/// 顶部全屏照片画廊 + 视差滑动 + 底部资料卡
class UserDetailScreen extends ConsumerStatefulWidget {
  final UserProfile user;

  const UserDetailScreen({super.key, required this.user});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  int _currentPhoto = 0;
  late PageController _photoController;

  @override
  void initState() {
    super.initState();
    _photoController = PageController();
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  UserProfile get user => widget.user;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // backgroundColor从theme获取
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ====== 照片画廊 ======
              SliverAppBar(
                expandedHeight: screenHeight * 0.55,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                leading: _circleButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
                actions: [
                  _circleButton(
                    icon: Icons.more_horiz,
                    onTap: () => _showOptions(context),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 照片轮播
                      if (user.avatarUrls.isNotEmpty)
                        PageView.builder(
                          controller: _photoController,
                          itemCount: user.avatarUrls.length,
                          onPageChanged: (i) =>
                              setState(() => _currentPhoto = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: user.avatarUrls[i],
                            fit: BoxFit.cover,
                            memCacheWidth: 800,
                            placeholder: (_, __) =>
                                Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                            errorWidget: (_, __, ___) =>
                                Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                          ),
                        )
                      else
                        Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.person,
                              size: 80, color: Theme.of(context).colorScheme.outline),
                        ),

                      // 照片指示器（顶部白线）
                      if (user.avatarUrls.length > 1)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 56,
                          left: 8,
                          right: 8,
                          child: Row(
                            children: List.generate(
                              user.avatarUrls.length,
                              (i) => Expanded(
                                child: Container(
                                  height: 3,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: i == _currentPhoto
                                        ? Colors.white
                                        : Colors.white.withValues(alpha:0.35),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // 底部渐变
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 120,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha:0.6),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 名字 + 年龄（照片上）
                      Positioned(
                        left: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${user.name}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (user.age != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '${user.age}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                                if (user.vipTier != null &&
                                    user.vipTier != 'none') ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: user.vipTier == 'diamond'
                                            ? [
                                                const Color(0xFF7C4DFF),
                                                const Color(0xFFE040FB)
                                              ]
                                            : [
                                                const Color(0xFFFFD700),
                                                const Color(0xFFFFA000)
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      user.vipTier == 'diamond' ? '💎' : '👑',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (user.city != null || user.jobTitle != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    if (user.jobTitle != null &&
                                        user.jobTitle!.isNotEmpty) ...[
                                      const Icon(Icons.work_outline,
                                          color: Colors.white70, size: 14),
                                      const SizedBox(width: 4),
                                      Text(user.jobTitle!,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14)),
                                    ],
                                    if (user.city != null &&
                                        user.city!.isNotEmpty) ...[
                                      if (user.jobTitle != null)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: Text('·',
                                              style: TextStyle(
                                                  color: Colors.white54)),
                                        ),
                                      const Icon(Icons.location_on_outlined,
                                          color: Colors.white70, size: 14),
                                      const SizedBox(width: 2),
                                      Text(user.city!,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14)),
                                    ],
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

              // ====== 资料详情 ======
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bio
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        Text('关于我',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 8),
                        Text(user.bio!,
                            style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                height: 1.5)),
                        const SizedBox(height: 24),
                      ],

                      // 基本信息标签
                      _buildInfoChips(),

                      const SizedBox(height: 24),

                      // 兴趣标签
                      if (user.tags.isNotEmpty) ...[
                        Text('兴趣爱好',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.tags
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFFF4D88)
                                              .withValues(alpha:0.1),
                                          const Color(0xFFFF8A5C)
                                              .withValues(alpha:0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(tag,
                                        style: const TextStyle(
                                          color: Color(0xFFFF4D88),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        )),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 生活方式
                      if (user.smoking != null || user.drinking != null) ...[
                        Text('生活方式',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 12),
                        if (user.smoking != null)
                          _lifestyleRow(
                              Icons.smoking_rooms, '吸烟', _smokingLabel(user.smoking!)),
                        if (user.drinking != null)
                          _lifestyleRow(
                              Icons.local_bar, '饮酒', _drinkingLabel(user.drinking!)),
                        const SizedBox(height: 24),
                      ],

                      const SizedBox(height: 60), // 留空给底部按钮
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ====== 底部操作栏 ======
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // NOPE
                  _actionButton(
                    icon: Icons.close,
                    color: Theme.of(context).colorScheme.error,
                    size: 54,
                    onTap: () => Navigator.pop(context, 'LEFT'),
                  ),
                  const SizedBox(width: 16),
                  // Super Like
                  _actionButton(
                    icon: Icons.star,
                    color: const Color(0xFF2196F3),
                    size: 46,
                    onTap: () => Navigator.pop(context, 'UP'),
                  ),
                  const SizedBox(width: 16),
                  // LIKE
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, 'RIGHT'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor:
                              const Color(0xFFFF4D88).withValues(alpha:0.4),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF4D88),
                                Color(0xFFFF8A5C)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.favorite,
                                    color: Colors.white, size: 22),
                                SizedBox(width: 8),
                                Text('喜欢',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChips() {
    final chips = <_InfoChip>[];
    if (user.height != null)
      chips.add(_InfoChip(Icons.height, '${user.height}cm'));
    if (user.education != null)
      chips.add(_InfoChip(Icons.school, _educationLabel(user.education!)));
    if (user.zodiac != null)
      chips.add(_InfoChip(Icons.auto_awesome, user.zodiac!));
    if (user.gender.isNotEmpty)
      chips.add(_InfoChip(
          user.gender == 'male' ? Icons.male : Icons.female,
          user.gender == 'male' ? '男' : '女'));

    if (chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('基本信息',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: chips
              .map((c) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.icon, size: 16, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(width: 6),
                        Text(c.label,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _lifestyleRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _circleButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha:0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha:0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha:0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.flag_outlined, color: Theme.of(context).colorScheme.error),
              title: const Text('举报'),
              onTap: () {
                Navigator.pop(context);
                showReportSheet(context, user.id, user.name);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: const Text('屏蔽'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('分享'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  String _educationLabel(String v) {
    switch (v) {
      case 'high_school': return '高中';
      case 'bachelor': return '本科';
      case 'master': return '硕士';
      case 'phd': return '博士';
      default: return v;
    }
  }

  String _smokingLabel(String v) {
    switch (v) {
      case 'never': return '从不';
      case 'occasionally': return '偶尔';
      case 'regularly': return '经常';
      default: return v;
    }
  }

  String _drinkingLabel(String v) {
    switch (v) {
      case 'never': return '从不';
      case 'occasionally': return '偶尔';
      case 'regularly': return '经常';
      default: return v;
    }
  }
}

class _InfoChip {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);
}
