import 'package:flutter/material.dart';

/// 网络状态包裹器
/// 移除了 dart:io 的 InternetAddress.lookup（Web 不支持）
/// 网络错误由各页面的 error state 统一处理
class NetworkAwareBanner extends StatelessWidget {
  final Widget child;
  const NetworkAwareBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
