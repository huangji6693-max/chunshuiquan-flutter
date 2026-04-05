import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../data/likes_repository.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/design_tokens.dart';

final likesProvider = FutureProvider.autoDispose<LikesResult>((ref) {
  return ref.watch(likesRepositoryProvider).getWhoLikesMe();
});

class LikesScreen extends ConsumerWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likesAsync = ref.watch(likesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('谁喜欢了我'),
        actions: [
          likesAsync.whenOrNull(
                data: (r) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Dt.pink.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${r.count}人',
                        style: const TextStyle(
                          color: Dt.pink,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: likesAsync.when(
        data: (result) {
          if (result.likes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Dt.pink.withValues(alpha:0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border,
                        size: 40, color: Dt.pink),
                  ),
                  const SizedBox(height: 16),
                  Text('你的故事还在等一个开始',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text('完善资料和照片，让更多人看到你的光芒',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 非VIP提示
              if (!result.isVip)
                GestureDetector(
                  onTap: () => context.push('/vip'),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Dt.vipGold, Dt.vipGoldDark],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Dt.vipGold.withValues(alpha:0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.workspace_premium,
                            color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('开通VIP，查看谁喜欢了你',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              SizedBox(height: 2),
                              Text('解锁头像和详细信息',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                ),

              // 列表
              Expanded(
                child: RefreshIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  onRefresh: () async {
                    ref.invalidate(likesProvider);
                  },
                  child: AnimationLimiter(
                    child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: result.likes.length,
                    itemBuilder: (_, i) =>
                        AnimationConfiguration.staggeredGrid(
                          position: i,
                          columnCount: 2,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 30,
                            child: FadeInAnimation(
                              child: _LikeCard(item: result.likes[i]),
                            ),
                          ),
                        ),
                  ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: Dt.pink)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('加载失败', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 6),
                Text('请检查网络后重试', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => ref.invalidate(likesProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LikeCard extends StatelessWidget {
  final LikeItem item;
  const _LikeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha:0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 头像（模糊 or 清晰）
          if (item.avatarUrl != null)
            item.blurred
                ? ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: CachedNetworkImage(
                      imageUrl: item.avatarUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 400,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: item.avatarUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 400,
                  )
          else
            Container(color: Theme.of(context).colorScheme.outlineVariant),

          // Super Like 标签
          if (item.direction == 'UP')
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 12),
                    SizedBox(width: 2),
                    Text('Super Like',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),

          // 底部信息
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
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
              child: Text(
                item.blurred
                    ? '${item.name ?? "?"}'
                    : '${item.name ?? "?"}${item.age != null ? ", ${item.age}" : ""}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // 模糊时的锁定图标
          if (item.blurred)
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, color: Colors.white, size: 24),
              ),
            ),
        ],
      ),
    );
  }
}
