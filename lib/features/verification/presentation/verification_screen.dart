import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../profile/data/upload_repository.dart';

final verificationStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/api/verification/status');
  return res.data as Map<String, dynamic>;
});

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _nameCtrl = TextEditingController();
  String? _idPhotoUrl;
  String? _selfieUrl;
  bool _uploading = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(verificationStatusProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('实名认证'),
        // backgroundColor从theme获取
        surfaceTintColor: Colors.transparent,
      ),
      body: statusAsync.when(
        data: (status) {
          final st = status['status'] as String? ?? 'none';

          // 已通过认证
          if (st == 'approved') return _buildApproved();
          // 审核中
          if (st == 'pending') return _buildPending();
          // 被拒绝或未认证 → 显示表单
          return _buildForm(st == 'rejected'
              ? status['rejectReason'] as String?
              : null);
        },
        loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Widget _buildApproved() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: const Icon(Icons.verified_user, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('认证已通过',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4CAF50))),
          const SizedBox(height: 8),
          Text('你的身份已验证，享受更高的信任度',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildPending() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFFA000), Color(0xFFFFD54F)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_top, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('审核中',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFA000))),
          const SizedBox(height: 8),
          Text('我们正在审核你的认证信息，通常需要1-3个工作日',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildForm(String? rejectReason) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 被拒提示
          if (rejectReason != null && rejectReason.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('上次被拒原因：$rejectReason',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                  ),
                ],
              ),
            ),

          // 说明卡
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                const Color(0xFFFF4D88).withOpacity(0.08),
                const Color(0xFFFF8A5C).withOpacity(0.08),
              ]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, color: Color(0xFFFF4D88), size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('为什么需要认证？',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('认证后获得蓝色徽章，增加曝光和信任度',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 真实姓名
          const Text('真实姓名',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: '请输入身份证上的姓名',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade700)),
            ),
          ),

          const SizedBox(height: 24),

          // 证件照
          const Text('证件照片',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text('上传身份证正面照片',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          const SizedBox(height: 8),
          _PhotoUploadBox(
            url: _idPhotoUrl,
            icon: Icons.credit_card,
            label: '点击上传证件照',
            uploading: _uploading,
            onTap: () => _uploadPhoto(isIdPhoto: true),
          ),

          const SizedBox(height: 24),

          // 手持自拍
          const Text('手持证件自拍',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text('手持身份证拍一张自拍照',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          const SizedBox(height: 8),
          _PhotoUploadBox(
            url: _selfieUrl,
            icon: Icons.face,
            label: '点击上传自拍',
            uploading: _uploading,
            onTap: () => _uploadPhoto(isIdPhoto: false),
          ),

          const SizedBox(height: 32),

          // 提交
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4D88),
                disabledBackgroundColor: Colors.grey.shade700,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Text('提交认证',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text('信息仅用于身份验证，不会公开展示',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  bool get _canSubmit =>
      !_submitting &&
      _nameCtrl.text.trim().isNotEmpty &&
      _idPhotoUrl != null &&
      _selfieUrl != null;

  Future<void> _uploadPhoto({required bool isIdPhoto}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: isIdPhoto ? ImageSource.gallery : ImageSource.camera,
        maxWidth: 1080,
        imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final url = await ref.read(uploadRepositoryProvider).uploadImage(File(picked.path));
      if (mounted) {
        setState(() {
          if (isIdPhoto) {
            _idPhotoUrl = url;
          } else {
            _selfieUrl = url;
          }
          _uploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('上传失败'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/verification/submit', data: {
        'realName': _nameCtrl.text.trim(),
        'idPhotoUrl': _idPhotoUrl,
        'selfieUrl': _selfieUrl,
      });
      HapticFeedback.mediumImpact();
      ref.invalidate(verificationStatusProvider);
    } on DioException catch (e) {
      if (mounted) {
        final msg = (e.response?.data as Map<String, dynamic>?)?['error'] ?? '提交失败';
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _PhotoUploadBox extends StatelessWidget {
  final String? url;
  final IconData icon;
  final String label;
  final bool uploading;
  final VoidCallback onTap;

  const _PhotoUploadBox({
    this.url,
    required this.icon,
    required this.label,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: url != null ? null : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: url != null ? const Color(0xFFFF4D88) : Colors.grey.shade700,
            width: url != null ? 2 : 1,
          ),
          image: url != null
              ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
              : null,
        ),
        child: url == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (uploading)
                    const CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFFF4D88))
                  else ...[
                    Icon(icon, size: 36, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(label,
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13)),
                  ],
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4D88),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
      ),
    );
  }
}
