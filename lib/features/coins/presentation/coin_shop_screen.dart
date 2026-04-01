import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/coin_repository.dart';

/// 金币余额Provider
final coinBalanceProvider = FutureProvider<int>((ref) {
  return ref.watch(coinRepositoryProvider).getBalance();
});

/// 金币流水Provider
final coinTransactionsProvider = FutureProvider<List<CoinTransaction>>((ref) {
  return ref.watch(coinRepositoryProvider).getTransactions();
});

class CoinShopScreen extends ConsumerStatefulWidget {
  const CoinShopScreen({super.key});

  @override
  ConsumerState<CoinShopScreen> createState() => _CoinShopScreenState();
}

class _CoinShopScreenState extends ConsumerState<CoinShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedPackage;
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
    final balanceAsync = ref.watch(coinBalanceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      body: CustomScrollView(
        slivers: [
          // 顶部渐变AppBar + 余额
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFFFF4D88),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // 金币图标动画
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.monetization_on_rounded,
                            color: Colors.amber, size: 40),
                      ),
                      const SizedBox(height: 12),
                      const Text('我的金币',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      balanceAsync.when(
                        data: (coins) => Text(
                          '$coins',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        loading: () => const SizedBox(
                          height: 42,
                          child: Center(
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                        ),
                        error: (_, __) => const Text('--',
                            style: TextStyle(color: Colors.white70, fontSize: 42)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFFF4D88),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFFFF4D88),
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                  tabs: const [
                    Tab(text: '充值'),
                    Tab(text: '流水记录'),
                  ],
                ),
              ),
            ),
          ),

          // TabBar 内容
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRechargeTab(),
                _buildTransactionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRechargeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('选择充值包',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 16),

          // 充值包网格
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: CoinRepository.packages
                .map((pkg) => _buildPackageCard(pkg))
                .toList(),
          ),

          const SizedBox(height: 24),

          // 购买按钮
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _selectedPackage != null && !_purchasing
                  ? _handlePurchase
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4D88),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: _selectedPackage != null ? 4 : 0,
                shadowColor: const Color(0xFFFF4D88).withOpacity(0.4),
              ),
              child: _purchasing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      _selectedPackage != null
                          ? '立即充值 ${CoinRepository.packages.firstWhere((p) => p.id == _selectedPackage).price}'
                          : '请选择充值包',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // 说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text('温馨提示',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• 金币是你传递心意的小小信使\n• 充值后金币不可退款\n• 如有问题请联系客服',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(CoinPackage pkg) {
    final isSelected = _selectedPackage == pkg.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedPackage = pkg.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4D88) : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF4D88).withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // 热门标签
            if (pkg.isPopular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)],
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                  child: const Text('热门',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ),

            // 内容
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on_rounded,
                      color: isSelected
                          ? const Color(0xFFFF4D88)
                          : Colors.amber.shade600,
                      size: 32),
                  const SizedBox(height: 6),
                  Text(
                    '${pkg.coins}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? const Color(0xFFFF4D88)
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pkg.price,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // 选中勾
            if (isSelected)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4D88),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    final txAsync = ref.watch(coinTransactionsProvider);

    return txAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('暂无交易记录',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 1),
          itemBuilder: (context, i) {
            final tx = transactions[i];
            final isIncome = tx.amount > 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(12) : Radius.zero,
                  bottom: i == transactions.length - 1
                      ? const Radius.circular(12)
                      : Radius.zero,
                ),
              ),
              child: Row(
                children: [
                  // 图标
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isIncome
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isIncome ? Icons.add_circle : Icons.remove_circle,
                      color: isIncome ? Colors.green : Colors.red.shade400,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 描述
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.note ?? _typeLabel(tx.type),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(tx.createdAt),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),

                  // 金额
                  Text(
                    '${isIncome ? '+' : ''}${tx.amount}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isIncome ? Colors.green : Colors.red.shade400,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('网络开小差了', style: TextStyle(color: Colors.grey.shade500)),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'recharge':
        return '充值';
      case 'gift_sent':
        return '送出礼物';
      case 'gift_received_bonus':
        return '收到礼物奖励';
      case 'daily_bonus':
        return '每日奖励';
      case 'admin_grant':
        return '系统赠送';
      default:
        return type;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }

  Future<void> _handlePurchase() async {
    if (_selectedPackage == null) return;
    setState(() => _purchasing = true);

    try {
      await ref
          .read(coinRepositoryProvider)
          .recharge(_selectedPackage!);

      // 刷新余额和流水
      ref.invalidate(coinBalanceProvider);
      ref.invalidate(coinTransactionsProvider);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('充值成功！'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('充值失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }
}
