import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

/// 全局网络状态横幅 — 断网时显示在页面顶部
/// 用法: 在 MaterialApp.builder 中包裹
class NetworkAwareBanner extends StatefulWidget {
  final Widget child;
  const NetworkAwareBanner({super.key, required this.child});

  @override
  State<NetworkAwareBanner> createState() => _NetworkAwareBannerState();
}

class _NetworkAwareBannerState extends State<NetworkAwareBanner> {
  bool _connected = true;
  Timer? _checker;

  @override
  void initState() {
    super.initState();
    _check();
    // 每10秒检查一次网络
    _checker = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  Future<void> _check() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (mounted) {
        setState(() => _connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty);
      }
    } catch (_) {
      if (mounted) setState(() => _connected = false);
    }
  }

  @override
  void dispose() {
    _checker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 断网横幅
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _connected ? 0 : 36,
          color: Theme.of(context).colorScheme.errorContainer,
          child: _connected
              ? const SizedBox.shrink()
              : const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('网络已断开，部分功能暂不可用',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
