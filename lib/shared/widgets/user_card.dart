import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../features/auth/domain/user_profile.dart';
import '../theme/design_tokens.dart';

/// 用户卡片 — Tinder 级别全屏卡片, 高级荷尔蒙风格
/// 多照片切换 / 卡片电影感 vignette / 底部毛玻璃信息面板 / 多层阴影
/// 主人原则: "卡片电影感 RadialGradient 暗角 vignette" 是高级感来源
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
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Dt.pink.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 2,
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

            // 卡片暗角 vignette — 电影感的核心 (主人原则)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.85,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.18),
                    ],
                  ),
                ),
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

            // 底部毛玻璃信息面板 — Glassmorphism 高级感
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
      // 无照片时——深色质感背景+居中首字母（不用彩色渐变避免塑料感）
      return Container(
        color: Dt.bgHighest,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Center(
                  child: Text(
                    widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '暂无照片',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 13,
                ),
              ),
            ],
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
          baseColor: Dt.bgHighest,
          highlightColor: Dt.bgElevated,
          child: Container(
            color: Dt.bgHighest,
          ),
        ),
        // [v4] 删除粉橙渐变 fallback — Ferrari 共识: 失败也用单色, 不加装饰
        errorWidget: (_, __, ___) => Container(
          color: Dt.bgHighest,
          child: Center(
            child: Text(
              widget.user.name.isNotEmpty ? widget.user.name[0] : '?',
              style: const TextStyle(
                  color: Dt.textTertiary,
                  fontSize: 80,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -2.4),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建底部毛玻璃信息面板
  Widget _buildInfoOverlay(UserProfile user) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 名字 + 年龄 — Lambo 风格紧 lh + 负字距
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(user.name,
                  style: const TextStyle(
                    color: Dt.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,  // [v4] w700→w600
                    letterSpacing: -0.8,           // [v4] -0.6→-0.8
                    height: 1.0,                    // [v4] 1.1→1.0
                  )),
              const SizedBox(width: 12),
              if (user.age != null)
                Text('${user.age}',
                    style: const TextStyle(
                      color: Dt.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.4,
                      height: 1.0,
                    )),
              const Spacer(),
              // 展开/收起箭头
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_up,
                color: Dt.textTertiary,
                size: 22,
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 城市 + 职业（次要信息）
          Row(
            children: [
              if (user.city?.isNotEmpty == true) ...[
                const Icon(Icons.location_on_outlined,
                    color: Dt.textSecondary, size: 14),
                const SizedBox(width: 3),
                Text(user.city!,
                    style: const TextStyle(
                        color: Dt.textSecondary, fontSize: 14)),
                const SizedBox(width: 12),
              ],
              if (user.jobTitle?.isNotEmpty == true) ...[
                const Icon(Icons.work_outline,
                    color: Dt.textSecondary, size: 14),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(user.jobTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Dt.textSecondary, fontSize: 14)),
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
              if (user.education?.isNotEmpty == true)
                _InfoTag(icon: Icons.school_outlined, text: user.education!),
              if (user.zodiac?.isNotEmpty == true)
                _InfoTag(icon: Icons.auto_awesome, text: user.zodiac!),
            ],
          ),

          // 展开后显示更多信息
          if (_expanded) ...[
            const SizedBox(height: 14),

            // Bio
            if (user.bio?.isNotEmpty == true) ...[
              const Text('关于我',
                  style: TextStyle(
                      color: Dt.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const SizedBox(height: 6),
              Text(user.bio!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.5)),
            ],

            // 吸烟/饮酒标签
            if ((user.smoking?.isNotEmpty == true) ||
                (user.drinking?.isNotEmpty == true)) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (user.smoking?.isNotEmpty == true)
                    _InfoTag(icon: Icons.smoking_rooms, text: user.smoking!),
                  if (user.drinking?.isNotEmpty == true)
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
                    color: const Color(0x1A000000),
                    borderRadius: Dt.rSm,
                    border: Border.all(color: Dt.borderSubtle, width: 1),
                  ),
                  child: Text(tag,
                      style: const TextStyle(
                        color: Dt.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      )),
                )).toList(),
              ),
            ],
          ] else ...[
            // 未展开时，Bio 预览（最多1行）
            if (user.bio?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(user.bio!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
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
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: Dt.rSm,
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

/// 信息小标签 — Dt v4 边界驱动风格 (cardMinimal)
class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        // [v4] 透明 + 1px borderSubtle, 替代纯色填充 (Sentry/Composio)
        color: const Color(0x1A000000),  // 10% 黑, 让照片透出
        borderRadius: Dt.rSm,
        border: Border.all(color: Dt.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Dt.textSecondary),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(
                color: Dt.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              )),
        ],
      ),
    );
  }
}
