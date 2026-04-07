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
          // Hero 区 — 紫金奢华渐变 + 金色多层光晕 (恢复"奢华张力")
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A2E),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2D1B69), Color(0xFF1A1A2E)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 28),
                      // 皇冠 — 多层金色发光
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Dt.vipGold, Dt.vipGoldDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Dt.vipGold.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 6,
                            ),
                            BoxShadow(
                              color: Dt.vipGold.withValues(alpha: 0.2),
                              blurRadius: 60,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.workspace_premium,
                            color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 18),
                      const Text('春水圈 VIP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(color: Color(0x66000000), blurRadius: 16),
                            ],
                          )),
                      const SizedBox(height: 10),
                      statusAsync.when(
                        data: (status) => status.isVip
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: status.isDiamond
                                        ? [Dt.boost, const Color(0xFFE040FB)]
                                        : [Dt.vipGold, Dt.vipGoldDark],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (status.isDiamond
                                              ? Dt.boost
                                              : Dt.vipGold)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${status.isDiamond ? "💎 钻石" : "👑 黄金"}会员 · 剩余 ${status.daysLeft} 天',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              )
                            : Text('让 每 一 次 心 动 都 不 留 遗 憾',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                    letterSpacing: 1.5)),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
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

          // ====== 购买按钮 — 金色多层光晕浮现 ======
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  decoration: BoxDecoration(
                    gradient: _selectedPlan != null
                        ? const LinearGradient(
                            colors: [Dt.vipGold, Dt.vipGoldDark],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    color: _selectedPlan == null ? Dt.bgElevated : null,
                    borderRadius: BorderRadius.circular(30),
                    border: _selectedPlan == null
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1)
                        : null,
                    boxShadow: _selectedPlan != null
                        ? [
                            BoxShadow(
                              color: Dt.vipGold.withValues(alpha: 0.55),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: Dt.vipGold.withValues(alpha: 0.25),
                              blurRadius: 60,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _selectedPlan != null && !_purchasing
                          ? _handlePurchase
                          : null,
                      child: Center(
                        child: _purchasing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Color(0xFF1a1408), strokeWidth: 2.5),
                              )
                            : Text(
                                _selectedPlan != null ? '立 即 开 通' : '请 选 择 套 餐',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 4,
                                  color: _selectedPlan != null
                                      ? const Color(0xFF1a1408)
                                      : Colors.white.withValues(alpha: 0.4),
                                ),
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
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: 130,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.18)
                  : Dt.bgElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : Colors.white.withValues(alpha: 0.12),
                width: isSelected ? 2 : 1,
              ),
              // 选中时多层发光浮现
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.5),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.2),
                        blurRadius: 48,
                        spreadRadius: 4,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
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
