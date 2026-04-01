import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../discover/data/discover_repository.dart';
import '../../discover/domain/user_profile.dart';
import '../../profile/presentation/user_detail_screen.dart';

/// 附近用户列表 Provider
final nearbyUsersProvider = FutureProvider.family<List<UserProfile>, double>(
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

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(nearbyUsersProvider(_radius));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      body: CustomScrollView(
        slivers: [
          // ====== 顶部 ======
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: const Text('附近的人'),
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
                    Text('${_radius.toInt()}km 范围内',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFFFF4D88),
                          inactiveTrackColor:
                              const Color(0xFFFF4D88).withOpacity(0.15),
                          thumbColor: const Color(0xFFFF4D88),
                          overlayColor:
                              const Color(0xFFFF4D88).withOpacity(0.1),
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
                          onChangeEnd: (_) =>
                              ref.invalidate(nearbyUsersProvider(_radius)),
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
                            color: const Color(0xFFFF4D88).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.explore_off,
                              size: 40, color: Color(0xFFFF4D88)),
                        ),
                        const SizedBox(height: 16),
                        Text('附近暂无用户',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text('试试扩大搜索范围',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }

              if (_isGridView) {
                return SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _NearbyCard(user: users[i]),
                      childCount: users.length,
                    ),
                  ),
                );
              } else {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) =>
                        _NearbyListTile(user: users[i]),
                    childCount: users.length,
                  ),
                );
              }
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF4D88))),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
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
                placeholder: (_, __) => Container(
                  color: Colors.grey.shade100,
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.person, size: 48, color: Colors.grey),
                ),
              )
            else
              Container(
                color: Colors.grey.shade100,
                child: const Icon(Icons.person, size: 48, color: Colors.grey),
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
                      Colors.black.withOpacity(0.7),
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
                              color: Colors.white,
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
                    if (user.city != null && user.city!.isNotEmpty)
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
                      color: Colors.green.withOpacity(0.4),
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
      MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)),
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
        MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)),
      ),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
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
                    errorWidget: (_, __, ___) =>
                        Container(color: Colors.grey.shade100),
                  )
                : Container(
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.person, color: Colors.grey),
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
            if (user.bio != null && user.bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(user.bio!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13)),
              ),
            if (user.city != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 2),
                    Text(user.city!,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
          ],
        ),
        trailing: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFF4D88).withOpacity(0.1),
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
