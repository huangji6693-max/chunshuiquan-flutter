import '../../../shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 录音按钮 — 点击提示功能即将上线
/// record 插件与当前 Gradle 版本不兼容，暂用 placeholder
class VoiceRecordButton extends StatelessWidget {
  final Future<void> Function(String filePath, int durationSeconds)? onRecordComplete;

  const VoiceRecordButton({super.key, this.onRecordComplete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('语音消息功能即将上线'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Dt.pink.withValues(alpha:0.1),
        ),
        child: const Icon(Icons.mic_none, color: Dt.pink, size: 22),
      ),
    );
  }
}
