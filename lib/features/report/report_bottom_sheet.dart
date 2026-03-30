import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chunshuiquan_flutter/features/report/report_repository.dart';
import '../../../core/errors/app_exception.dart';

class ReportBottomSheet extends ConsumerStatefulWidget {
  final String targetUserId;
  final String targetUserName;

  const ReportBottomSheet({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
  });

  @override
  ConsumerState<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends ConsumerState<ReportBottomSheet> {
  ReportReason? _selectedReason;
  final _descCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (_selectedReason == null) {
      setState(() => _error = '请选择举报原因');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(reportRepositoryProvider).reportUser(
        reportedId: widget.targetUserId,
        reason: _selectedReason!,
        description: _descCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, 'reported');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('举报已提交，我们会尽快处理')),
        );
      }
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _block() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(reportRepositoryProvider).blockUser(widget.targetUserId);
      if (mounted) {
        Navigator.pop(context, 'blocked');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已屏蔽 ${widget.targetUserName}')),
        );
      }
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('举报 ${widget.targetUserName}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            // 屏蔽快捷按钮
            OutlinedButton.icon(
              onPressed: _loading ? null : _block,
              icon: const Icon(Icons.block),
              label: const Text('屏蔽此用户'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
            const Divider(height: 32),
            const Text('举报原因', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...ReportReason.values.map((r) => RadioListTile<ReportReason>(
              value: r,
              groupValue: _selectedReason,
              onChanged: (v) => setState(() => _selectedReason = v),
              title: Text(r.label),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                hintText: '补充说明（可选）',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 2,
              maxLength: 200,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('提交举报'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 从任意页面调用举报底部弹窗
Future<String?> showReportSheet(
    BuildContext context, String userId, String userName) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ReportBottomSheet(
      targetUserId: userId,
      targetUserName: userName,
    ),
  );
}
