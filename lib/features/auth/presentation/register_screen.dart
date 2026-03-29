import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../../../core/errors/app_exception.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'male';
  bool _loading = false;
  String? _error;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      setState(() => _error = '请选择生日');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        birthDate: '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2,'0')}-${_birthDate!.day.toString().padLeft(2,'0')}',
        gender: _gender,
      );
      if (mounted) context.go('/onboarding');
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('创建账号')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: const Key('name'),
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: '昵称'),
                  validator: (v) => v == null || v.trim().isEmpty ? '请输入昵称' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('email'),
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: '邮箱'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@') ? '请输入有效邮箱' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('password'),
                  controller: _passCtrl,
                  decoration: const InputDecoration(labelText: '密码'),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6 ? '密码至少6位' : null,
                ),
                const SizedBox(height: 16),
                // 生日选择
                GestureDetector(
                  key: const Key('birth_date'),
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          _birthDate == null
                              ? '选择生日'
                              : '${_birthDate!.year}年${_birthDate!.month}月${_birthDate!.day}日',
                          style: TextStyle(
                            color: _birthDate == null ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 性别选择
                Row(
                  children: [
                    Expanded(
                      child: _GenderBtn(
                        label: '男', value: 'male', selected: _gender == 'male',
                        onTap: () => setState(() => _gender = 'male'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GenderBtn(
                        label: '女', value: 'female', selected: _gender == 'female',
                        onTap: () => setState(() => _gender = 'female'),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('register_btn'),
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('注册'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderBtn extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _GenderBtn({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          border: Border.all(color: selected ? primary : const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          )),
        ),
      ),
    );
  }
}
