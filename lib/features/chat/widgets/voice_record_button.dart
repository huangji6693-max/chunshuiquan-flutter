import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// 录音按钮 — 长按录音，松手发送
/// 返回录音文件路径和时长(秒)
class VoiceRecordButton extends StatefulWidget {
  final Future<void> Function(String filePath, int durationSeconds) onRecordComplete;

  const VoiceRecordButton({super.key, required this.onRecordComplete});

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton> {
  final _recorder = AudioRecorder();
  bool _recording = false;
  int _seconds = 0;
  Timer? _timer;
  String? _filePath;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      _filePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _filePath!,
      );

      HapticFeedback.heavyImpact();
      setState(() {
        _recording = true;
        _seconds = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
        if (_seconds >= 60) _stopRecording(); // 最长60秒
      });
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();

    if (mounted) setState(() => _recording = false);

    if (path != null && _seconds >= 1) {
      HapticFeedback.mediumImpact();
      await widget.onRecordComplete(path, _seconds);
    }
  }

  void _cancelRecording() async {
    _timer?.cancel();
    await _recorder.stop();
    if (mounted) setState(() => _recording = false);

    // 删除临时文件
    if (_filePath != null) {
      try {
        await File(_filePath!).delete();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_recording) {
      return Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 录音时长
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 取消
                GestureDetector(
                  onTap: _cancelRecording,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.grey, size: 28),
                  ),
                ),

                // 发送
                GestureDetector(
                  onTap: _stopRecording,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFFFF4D88), Color(0xFFFF8A5C)]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 未录音状态：显示麦克风按钮
    return GestureDetector(
      onLongPress: _startRecording,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFF4D88).withOpacity(0.1),
        ),
        child: const Icon(Icons.mic_none,
            color: Color(0xFFFF4D88), size: 22),
      ),
    );
  }
}
