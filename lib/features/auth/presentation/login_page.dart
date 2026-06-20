import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
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

  @override
  void dispose() { _emailCtrl.dispose(); _pwdCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _pwdCtrl.text.isEmpty) { _toast('请输入邮箱和密码'); return; }
    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).login(_emailCtrl.text.trim(), _pwdCtrl.text);
      if (mounted) context.go('/');
    } catch (e) { if (mounted) _toast(e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

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
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 32),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.outline),
                    boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: isDark ? 0.08 : 0.15), blurRadius: 32, offset: const Offset(0, 12))],
                  ),
                  child: Center(child: Text('S2', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cs.primary, letterSpacing: 1))),
                ),
                const SizedBox(height: 20),
                Text('Sub2API Monitor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text('AI API 网关管理面板', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, letterSpacing: 1)),
                const SizedBox(height: 44),
                TextField(
                  controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 14, color: cs.onSurface),
                  decoration: const InputDecoration(hintText: '邮箱地址', prefixIcon: Icon(Icons.email_outlined, size: 18)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _pwdCtrl, obscureText: _obscure, onSubmitted: (_) => _login(),
                  style: TextStyle(fontSize: 14, color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: '密码', prefixIcon: const Icon(Icons.lock_outlined, size: 18),
                    suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18), onPressed: () => setState(() => _obscure = !_obscure)),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(height: 50, child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('授 权 登 录', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 2)),
                )),
                const SizedBox(height: 40),
                Row(children: [
                  Expanded(child: Container(height: 1, color: cs.outlineVariant)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.hexagon, size: 10, color: cs.onSurfaceVariant)),
                  Expanded(child: Container(height: 1, color: cs.outlineVariant)),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
