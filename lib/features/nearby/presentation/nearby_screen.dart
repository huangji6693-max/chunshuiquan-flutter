import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../discover/data/discover_repository.dart';
import '../../discover/domain/user_profile.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../profile/presentation/user_detail_screen.dart';
import '../../../shared/widgets/page_transitions.dart';

/// 附近用户列表 Provider
final nearbyUsersProvider = FutureProvider.autoDispose.family<List<UserProfile>, double>(
  (ref, radius) async {
    return ref.watch(discoverRepositoryProvider).getNearby(radiusKm: radius);
  },
);

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  double _radius = 50;
  bool _isGridView = true;
  Timer? _radiusDebounce;

  @override
  void dispose() {
    _radiusDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(nearbyUsersProvider(_radius));

    return Scaffold(
      
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () async {
          ref.invalidate(nearbyUsersProvider(_radius));
        },
        child: AnimationLimiter(
          child: CustomScrollView(
        slivers: [
          // ====== 顶部 ======
          SliverAppBar(
            floating: true,
            
            surfaceTintColor: Colors.transparent,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFFF4D88)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 10),
                const Text('附近的人'),
              ],
            ),
            actions: [
              // 切换视图
              IconButton(
                icon: Icon(
                  _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  color: const Color(0xFFFF4D88),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isGridView = !_isGridView);
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Icon(Icons.location_on,
                        color: const Color(0xFFFF4D88), size: 18),
                    const SizedBox(width: 6),
                    Text('${_radius.toInt()} km',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFFFF4D88))),
                    const SizedBox(width: 4),
                    Text('范围内',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFFFF4D88),
                          inactiveTrackColor:
                              const Color(0xFFFF4D88).withValues(alpha: 0.15),
                          thumbColor: const Color(0xFFFF4D88),
                          overlayColor:
                              const Color(0xFFFF4D88).withValues(alpha: 0.1),
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7),
                        ),
                        child: Slider(
                          value: _radius,
                          min: 5,
                          max: 200,
                          divisions: 39,
                          onChanged: (v) => setState(() => _radius = v),
                          onChangeEnd: (_) {
                            _radiusDebounce?.cancel();
                            _radiusDebounce = Timer(
                              const Duration(milliseconds: 500),
                              () => ref.invalidate(nearbyUsersProvider(_radius)),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ====== 内容 ======
          usersAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4D88).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.explore_off,
                              size: 40, color: Color(0xFFFF4D88)),
                        ),
                        const SizedBox(height: 16),
                        Text('这片星空暂时只有你',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text('试试把范围拉大一点',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }

              if (_isGridView) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => AnimationConfiguration.staggeredGrid(
                        position: i,
                        columnCount: 2,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 30,
                          child: FadeInAnimation(
                            child: _NearbyCard(user: users[i]),
                          ),
                        ),
                      ),
                      childCount: users.length,
                    ),
                  ),
                );
              } else {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => AnimationConfiguration.staggeredList(
                      position: i,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 30,
                        child: FadeInAnimation(
                          child: _NearbyListTile(user: users[i]),
                        ),
                      ),
                    ),
                    childCount: users.length,
                  ),
                );
              }
            },
            loading: () => const SliverFillRemaining(
              child: NearbySkeleton(),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('加载失败', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 6),
                      Text(
                        e.toString().contains('经纬度')
                            ? '需要开启定位权限，在个人资料中更新位置信息'
                            : '请检查网络后重试',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(nearbyUsersProvider(_radius)),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('重试'),
                      ),
                    ],
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
}

// ====== 网格卡片 ======
class _NearbyCard extends StatelessWidget {
  final UserProfile user;
  const _NearbyCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final avatar = (user.avatarUrls.isNotEmpty) ? user.avatarUrls.first : null;

    return GestureDetector(
      onTap: () => _openProfile(context),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 照片
            if (avatar != null)
              CachedNetworkImage(
                imageUrl: avatar,
                fit: BoxFit.cover,
                memCacheWidth: 400,
                placeholder: (_, __) => Container(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  child: Icon(Icons.person, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              )
            else
              Container(
                color: Theme.of(context).colorScheme.outlineVariant,
                child: Icon(Icons.person, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),

            // 底部渐变信息
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 32, 12, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${user.name}, ${user.age}',
                            style: const TextStyle(
                              
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.vipTier != null && user.vipTier != 'none') ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: user.vipTier == 'diamond'
                                ? const Color(0xFFE040FB)
                                : const Color(0xFFFFD700),
                          ),
                        ],
                      ],
                    ),
                    if (user.city?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.white70, size: 12),
                            const SizedBox(width: 2),
                            Text(user.city!,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 在线状态
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      fadeSlideRoute(UserDetailScreen(user: user)),
    );
  }
}

// ====== 列表项 ======
class _NearbyListTile extends StatelessWidget {
  final UserProfile user;
  const _NearbyListTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final avatar = (user.avatarUrls.isNotEmpty) ? user.avatarUrls.first : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        fadeSlideRoute(UserDetailScreen(user: user)),
      ),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 60,
            height: 60,
            child: avatar != null
                ? CachedNetworkImage(
                    imageUrl: avatar,
                    fit: BoxFit.cover,
                    memCacheWidth: 200,
                    errorWidget: (_, __, ___) =>
                        Container(color: Theme.of(context).colorScheme.outlineVariant),
                  )
                : Container(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
          ),
        ),
        title: Row(
          children: [
            Text('${user.name}, ${user.age}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (user.vipTier != null && user.vipTier != 'none') ...[
              const SizedBox(width: 4),
              Icon(
                Icons.verified,
                size: 16,
                color: user.vipTier == 'diamond'
                    ? const Color(0xFFE040FB)
                    : const Color(0xFFFFD700),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.bio?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(user.bio!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
              ),
            if (user.city != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(user.city!,
                        style: TextStyle(
                            fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
          ],
        ),
        trailing: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFF4D88).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite_border,
              color: Color(0xFFFF4D88), size: 18),
        ),
      ),
    ),
    );
  }
}
