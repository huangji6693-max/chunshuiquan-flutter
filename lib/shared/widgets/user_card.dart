import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../features/auth/domain/user_profile.dart';

/// 用户卡片 - Tinder级别的全屏卡片
/// 支持多照片切换、照片进度条、点击展开详情
class UserCard extends StatefulWidget {
  final UserProfile user;
  const UserCard({super.key, required this.user});

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  int _currentPhotoIndex = 0;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final photos = user.avatarUrls.isNotEmpty ? user.avatarUrls : [''];
    final hasMultiplePhotos = photos.length > 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 背景图片
            _buildPhoto(photos),

            // 照片左右点击切换区域
            if (hasMultiplePhotos)
              Positioned.fill(
                child: Row(
                  children: [
                    // 左侧点击区域 - 上一张
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          if (_currentPhotoIndex > 0) {
                            setState(() => _currentPhotoIndex--);
                          }
                        },
                        child: const SizedBox.expand(),
                      ),
                    ),
                    // 右侧点击区域 - 下一张
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          if (_currentPhotoIndex < photos.length - 1) {
                            setState(() => _currentPhotoIndex++);
                          }
                        },
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),

            // 顶部照片进度条指示器
            if (hasMultiplePhotos)
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Row(
                  children: List.generate(photos.length, (i) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1.5),
                          color: i == _currentPhotoIndex
                              ? Colors.white
                              : Colors.white.withValues(alpha:0.35),
                        ),
                      ),
                    );
                  }),
                ),
              ),

            // 底部毛玻璃面板 + 信息
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: _buildInfoOverlay(user),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建当前显示的照片
  Widget _buildPhoto(List<String> photos) {
    final url = photos[_currentPhotoIndex.clamp(0, photos.length - 1)];
    if (url.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            widget.user.name.isNotEmpty ? widget.user.name[0] : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 80,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: CachedNetworkImage(
        key: ValueKey('photo_$_currentPhotoIndex'),
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 800,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          highlightColor: Theme.of(context).colorScheme.outlineVariant,
          child: Container(
            color: Colors.white,
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              widget.user.name.isNotEmpty ? widget.user.name[0] : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 80,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建底部信息遮罩层
  Widget _buildInfoOverlay(UserProfile user) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 名字 + 年龄
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    height: 1.1,
                  )),
              const SizedBox(width: 10),
              if (user.age != null)
                Text('${user.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w300,
                      height: 1.1,
                    )),
              const Spacer(),
              // 展开/收起箭头
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_up,
                color: Colors.white60,
                size: 24,
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 城市 + 职业（次要信息）
          Row(
            children: [
              if (user.city != null && user.city!.isNotEmpty) ...[
                const Icon(Icons.location_on_outlined,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 3),
                Text(user.city!,
                    style: const TextStyle(
                        color: Color(0xB3FFFFFF), fontSize: 15)),
                const SizedBox(width: 12),
              ],
              if (user.jobTitle != null && user.jobTitle!.isNotEmpty) ...[
                const Icon(Icons.work_outline,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(user.jobTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xB3FFFFFF), fontSize: 15)),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // 身高/学历/星座 小标签
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (user.height != null)
                _InfoTag(icon: Icons.straighten, text: '${user.height}cm'),
              if (user.education != null && user.education!.isNotEmpty)
                _InfoTag(icon: Icons.school_outlined, text: user.education!),
              if (user.zodiac != null && user.zodiac!.isNotEmpty)
                _InfoTag(icon: Icons.auto_awesome, text: user.zodiac!),
            ],
          ),

          // 展开后显示更多信息
          if (_expanded) ...[
            const SizedBox(height: 14),

            // Bio
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const Text('关于我',
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const SizedBox(height: 6),
              Text(user.bio!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 14,
                      height: 1.5)),
            ],

            // 吸烟/饮酒标签
            if ((user.smoking != null && user.smoking!.isNotEmpty) ||
                (user.drinking != null && user.drinking!.isNotEmpty)) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (user.smoking != null && user.smoking!.isNotEmpty)
                    _InfoTag(icon: Icons.smoking_rooms, text: user.smoking!),
                  if (user.drinking != null && user.drinking!.isNotEmpty)
                    _InfoTag(icon: Icons.local_bar, text: user.drinking!),
                ],
              ),
            ],

            // 兴趣标签
            if (user.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: user.tags.take(6).map((tag) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 0.8),
                  ),
                  child: Text(tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      )),
                )).toList(),
              ),
            ],
          ] else ...[
            // 未展开时，Bio 预览（最多1行）
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(user.bio!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 14,
                    height: 1.3,
                  )),
            ],
            // 未展开时，简短显示兴趣标签
            if (user.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: user.tags.take(4).map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha:0.3),
                            width: 0.8),
                      ),
                      child: Text(tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// 信息小标签组件
class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha:0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
