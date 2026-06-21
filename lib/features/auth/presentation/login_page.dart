import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/errors/app_exception.dart';
import '../../../shared/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  /// 当前表单错误提示（null 表示无错误）。任何输入变化都会清空。
  String? _errorText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  /// 输入变化时清除错误提示。
  void _clearError() {
    if (_errorText != null) setState(() => _errorText = null);
  }

  /// 简单邮箱格式校验：非空且包含 @。
  bool _isEmailValid(String s) {
    final t = s.trim();
    return t.isNotEmpty && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
  }

  Future<void> _login() async {
    // 校验前先清除旧错误
    setState(() => _errorText = null);

    final email = _emailCtrl.text.trim();
    final pwd = _pwdCtrl.text;

    if (email.isEmpty && pwd.isEmpty) {
      setState(() => _errorText = '请输入邮箱和密码');
      return;
    }
    if (email.isEmpty) {
      setState(() => _errorText = '请输入邮箱地址');
      return;
    }
    if (!_isEmailValid(email)) {
      setState(() => _errorText = '邮箱地址格式不正确');
      return;
    }
    if (pwd.isEmpty) {
      setState(() => _errorText = '请输入密码');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).login(email, pwd);
      if (mounted) context.go('/');
    } on AppException catch (e) {
      if (mounted) setState(() => _errorText = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorText = '登录失败，请重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.outline),
                      boxShadow: [
                        BoxShadow(
                            color: cs.primary
                                .withValues(alpha: isDark ? 0.08 : 0.15),
                            blurRadius: 32,
                            offset: const Offset(0, 12))
                      ],
                    ),
                    child: Center(
                        child: Text('S2',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                                letterSpacing: 1))),
                  ),
                  const SizedBox(height: 20),
                  Text('Sub2API Monitor',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('AI API 网关管理面板',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 1)),
                  const SizedBox(height: 44),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: TextStyle(fontSize: 14, color: cs.onSurface),
                    onChanged: (_) => _clearError(),
                    decoration: const InputDecoration(
                        hintText: '邮箱地址',
                        prefixIcon: Icon(Icons.email_outlined, size: 18)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _pwdCtrl,
                    obscureText: _obscure,
                    onSubmitted: (_) => _login(),
                    style: TextStyle(fontSize: 14, color: cs.onSurface),
                    onChanged: (_) => _clearError(),
                    decoration: InputDecoration(
                      hintText: '密码',
                      prefixIcon: const Icon(Icons.lock_outlined, size: 18),
                      suffixIcon: IconButton(
                          icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 错误提示条：有错误时显示红色文案，无错误时占位保持高度稳定
                  SizedBox(
                    height: 32,
                    child: _errorText == null
                        ? const SizedBox.shrink()
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 16, color: cs.error),
                              const SizedBox(width: 6),
                              Expanded(
                                  child: Text(_errorText!,
                                      style: TextStyle(
                                          fontSize: 12, color: cs.error),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('授 权 登 录',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2)),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                          child:
                              Container(height: 1, color: cs.outlineVariant)),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.hexagon,
                              size: 10, color: cs.onSurfaceVariant)),
                      Expanded(
                          child:
                              Container(height: 1, color: cs.outlineVariant)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
