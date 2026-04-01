import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// 通用骨架屏组件 — Shimmer 微光扫描效果
/// 替代所有 CircularProgressIndicator，让加载状态看起来顶级

/// 发现页骨架屏（卡片形状）
class DiscoverSkeleton extends StatelessWidget {
  const DiscoverSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade800,
        highlightColor: Colors.grey.shade700,
        child: Column(
          children: [
            // 大卡片
            Container(
              height: MediaQuery.of(context).size.height * 0.55,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            // 三个按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (_) => Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  shape: BoxShape.circle,
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

/// 匹配列表骨架屏
class MatchesSkeleton extends StatelessWidget {
  const MatchesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 新匹配头像行
          SizedBox(
            height: 90,
            child: Row(
              children: List.generate(4, (_) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800, shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(width: 40, height: 10, color: Colors.white),
                  ],
                ),
              )),
            ),
          ),
          const SizedBox(height: 16),
          // 消息列表项
          ...List.generate(6, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 100, height: 14, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(width: 180, height: 12, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

/// 动态流骨架屏
class MomentsSkeleton extends StatelessWidget {
  const MomentsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(3, (_) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像行
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700, shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 80, height: 12, color: Colors.grey),
                      const SizedBox(height: 4),
                      Container(width: 50, height: 10, color: Colors.grey),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(width: double.infinity, height: 14, color: Colors.grey),
              const SizedBox(height: 6),
              Container(width: 200, height: 14, color: Colors.grey),
              const SizedBox(height: 12),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}

/// 附近的人网格骨架屏
class NearbySkeleton extends StatelessWidget {
  const NearbySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: GridView.count(
        padding: const EdgeInsets.all(12),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
        children: List.generate(6, (_) => Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(18),
          ),
        )),
      ),
    );
  }
}

/// 通用小骨架条
class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
