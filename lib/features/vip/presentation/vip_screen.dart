import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/vip_repository.dart';
import '../../../shared/theme/design_tokens.dart';

final vipStatusProvider = FutureProvider.autoDispose<VipStatus>((ref) {
  return ref.watch(vipRepositoryProvider).getStatus();
});

class VipScreen extends ConsumerStatefulWidget {
  const VipScreen({super.key});

  @override
  ConsumerState<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends ConsumerState<VipScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedPlan;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(vipStatusProvider);

    return Scaffold(
      
      body: CustomScrollView(
        slivers: [
          // ====== 顶部展示区 ======
          // [v4] Hero 区 — Lambo 宣言时刻 + Sanity 单色 + 金色径向光晕
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Dt.bgDeep,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Dt.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // [v4] 金色径向光晕替代紫色线性渐变
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.3),
                        radius: 0.9,
                        colors: [Color(0x33FFD700), Dt.bgDeep],
                        stops: [0.0, 0.65],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        // [v4] 皇冠 — 单层光晕, 删 spreadRadius 装饰
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Dt.vipGold,
                            boxShadow: [
                              BoxShadow(
                                color: Dt.vipGold.withValues(alpha: 0.25),
                                blurRadius: 28,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.workspace_premium,
                              color: Color(0xFF1a1408), size: 38),
                        ),
                        const SizedBox(height: 24),
                        // [v4] displayHero 风格宣言: 48px w600 lh0.96 -1.4
                        const Text('春水圈 VIP',
                            style: TextStyle(
                              color: Dt.textPrimary,
                              fontSize: 44,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -1.2,
                              height: 0.96,
                            )),
                        const SizedBox(height: 12),
                        // [v4] 状态/标语 — Sanity label 极简
                        statusAsync.when(
                          data: (status) => status.isVip
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0x1AFFD700),
                                    borderRadius: Dt.rPill,
                                    border: Border.all(
                                        color: Dt.vipGold.withValues(alpha: 0.4),
                                        width: 1),
                                  ),
                                  child: Text(
                                    '${status.isDiamond ? "钻石" : "黄金"}会员 · 剩余 ${status.daysLeft} 天',
                                    style: const TextStyle(
                                        color: Dt.vipGold,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        letterSpacing: 0.5),
                                  ),
                                )
                              : const Text('让 每 一 次 心 动 都 不 留 遗 憾',
                                  style: TextStyle(
                                      color: Dt.textTertiary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 2)),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ====== 特权展示 ======
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF252547),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Dt.vipGold.withValues(alpha:0.2)),
              ),
              child: Column(
                children: [
                  _FeatureRow(
                    icon: Icons.visibility,
                    gold: '查看谁喜欢我',
                    diamond: '查看谁喜欢我',
                    goldColor: Dt.vipGold,
                    diamondColor: const Color(0xFFE040FB),
                  ),
                  _FeatureRow(
                    icon: Icons.swipe,
                    gold: '无限滑动',
                    diamond: '无限滑动',
                    goldColor: Dt.vipGold,
                    diamondColor: const Color(0xFFE040FB),
                  ),
                  _FeatureRow(
                    icon: Icons.star,
                    gold: '5次/天 Super Like',
                    diamond: '无限 Super Like',
                    goldColor: Dt.vipGold,
                    diamondColor: const Color(0xFFE040FB),
                  ),
                  _FeatureRow(
                    icon: Icons.flash_on,
                    gold: '每月1次曝光加速',
                    diamond: '每周1次曝光加速',
                    goldColor: Dt.vipGold,
                    diamondColor: const Color(0xFFE040FB),
                  ),
                  _FeatureRow(
                    icon: Icons.verified,
                    gold: '金色徽章',
                    diamond: '钻石徽章 + 置顶',
                    goldColor: Dt.vipGold,
                    diamondColor: const Color(0xFFE040FB),
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),

          // ====== 套餐选择 Tab ======
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: const Color(0xFF252547),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                onTap: (_) => setState(() => _selectedPlan = null),
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Dt.vipGold, Dt.vipGoldDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
                dividerHeight: 0,
                tabs: const [
                  Tab(text: '👑 黄金'),
                  Tab(text: '💎 钻石'),
                ],
              ),
            ),
          ),

          // ====== 套餐卡片 ======
          SliverToBoxAdapter(
            child: SizedBox(
              height: 190,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPlansRow(VipRepository.goldPlans, Dt.vipGold),
                  _buildPlansRow(VipRepository.diamondPlans, const Color(0xFFE040FB)),
                ],
              ),
            ),
          ),

          // ====== 购买按钮 ======
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedPlan != null && !_purchasing
                      ? _handlePurchase
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: _selectedPlan != null ? 8 : 0,
                    shadowColor: Dt.vipGold.withValues(alpha:0.4),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: _selectedPlan != null
                          ? const LinearGradient(
                              colors: [Dt.vipGold, Dt.vipGoldDark])
                          : null,
                      color: _selectedPlan == null ? Dt.bgHighest : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: _purchasing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              _selectedPlan != null ? '立即开通' : '请选择套餐',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _selectedPlan != null
                                    ? Dt.textPrimary
                                    : Colors.white60,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansRow(List<VipPlan> plans, Color accentColor) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      itemCount: plans.length,
      itemBuilder: (context, i) {
        final plan = plans[i];
        final isSelected = _selectedPlan == plan.id;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedPlan = plan.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha:0.15)
                  : const Color(0xFF252547),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? accentColor : Colors.white12,
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha:0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // 性价比标签
                if (plan.isBestValue)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          accentColor,
                          accentColor.withValues(alpha:0.7),
                        ]),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14)),
                      ),
                      child: const Text('最划算',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),

                // 内容
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (plan.isBestValue) const SizedBox(height: 8),
                      Text(plan.label,
                          style: TextStyle(
                            color: isSelected ? accentColor : Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 8),
                      Text(plan.price,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          )),
                      if (plan.originalPrice != null) ...[
                        const SizedBox(height: 2),
                        Text(plan.originalPrice!,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.white38,
                            )),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${(double.parse(plan.price.replaceAll('¥', '')) / (plan.days / 30)).toStringAsFixed(1)}/月',
                        style: TextStyle(
                          color: accentColor.withValues(alpha:0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePurchase() async {
    if (_selectedPlan == null) return;
    setState(() => _purchasing = true);

    try {
      await ref.read(vipRepositoryProvider).subscribe(_selectedPlan!);
      ref.invalidate(vipStatusProvider);

      if (mounted) {
        HapticFeedback.heavyImpact();
        showDialog(
          context: context,
          builder: (_) => _VipSuccessDialog(
            isDiamond: _selectedPlan!.startsWith('diamond'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }
}

// ====== 特权对比行 ======
class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String gold;
  final String diamond;
  final Color goldColor;
  final Color diamondColor;
  final bool isLast;

  const _FeatureRow({
    required this.icon,
    required this.gold,
    required this.diamond,
    required this.goldColor,
    required this.diamondColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.white.withValues(alpha:0.06))),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: goldColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(gold,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: diamondColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(diamond,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ====== 开通成功弹窗 ======
class _VipSuccessDialog extends StatelessWidget {
  final bool isDiamond;
  const _VipSuccessDialog({required this.isDiamond});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDiamond
                ? [Dt.boost, const Color(0xFF3D1E8E)]
                : [Dt.vipGoldDark, const Color(0xFFE65100)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isDiamond
                      ? Dt.boost
                      : Dt.vipGold)
                  .withValues(alpha:0.4),
              blurRadius: 32,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isDiamond ? '💎' : '👑', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              '恭喜开通${isDiamond ? "钻石" : "黄金"}会员！',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDiamond ? '已赠送200金币' : '已赠送100金币',
              style: TextStyle(
                  color: Colors.white.withValues(alpha:0.8), fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: isDiamond
                      ? Dt.boost
                      : const Color(0xFFE65100),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('开启心动之旅 💕',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
