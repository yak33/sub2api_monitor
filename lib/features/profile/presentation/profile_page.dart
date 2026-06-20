import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final user = auth?.user;

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.outline),
            boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))]),
          child: Column(children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: cs.primary.withValues(alpha: 0.2))),
                child: Center(child: Text((user?.email ?? '?')[0].toUpperCase(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: cs.primary)))),
            const SizedBox(height: 12),
            Text(user?.email ?? '未登录', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
            if (user?.isAdmin == true) ...[
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text('管理员', style: TextStyle(fontSize: 10, color: cs.primary, letterSpacing: 0.5))),
            ],
          ]),
        ),
        const SizedBox(height: 20),
        _Tile(icon: Icons.vpn_key_outlined, title: 'API 密钥', cs: cs, onTap: () => context.push('/keys')),
        _Tile(icon: Icons.subscriptions_outlined, title: '订阅管理', cs: cs, onTap: () => context.push('/subscriptions')),
        _Tile(icon: Icons.card_giftcard, title: '兑换码', cs: cs, onTap: () => _redeem(context, ref)),
        _Tile(icon: Icons.account_balance_wallet_outlined, title: '充值', cs: cs, onTap: () {}),
        _Tile(icon: Icons.notifications_outlined, title: '公告', cs: cs, onTap: () {}),
        const SizedBox(height: 16),
        _Tile(icon: Icons.settings_outlined, title: '设置', cs: cs, onTap: () => context.push('/settings')),
        _Tile(icon: Icons.info_outlined, title: '关于', cs: cs, onTap: () => _about(context)),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () async {
            final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('退出登录'), content: const Text('确定要退出当前账号吗？'), actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: Text('退出', style: TextStyle(color: cs.error))),
            ]));
            if (ok == true) { await ref.read(authStateProvider.notifier).logout(); if (context.mounted) context.go('/login'); }
          },
          icon: Icon(Icons.logout, color: cs.error, size: 18),
          label: Text('退出登录', style: TextStyle(color: cs.error)),
          style: OutlinedButton.styleFrom(side: BorderSide(color: cs.outline), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        )),
      ]),
    );
  }

  void _redeem(BuildContext ctx, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(context: ctx, builder: (c) => AlertDialog(title: const Text('兑换码'), content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '请输入兑换码')), actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text('取消')),
      ElevatedButton(onPressed: () async {
        if (ctrl.text.isNotEmpty) {
          try { await ref.read(apiClientProvider).redeemCode(ctrl.text.trim()); if (c.mounted) Navigator.pop(c); if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('兑换成功'))); }
          catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('兑换失败: $e'))); }
        }
      }, child: const Text('兑换')),
    ]));
  }

  void _about(BuildContext ctx) => showAboutDialog(context: ctx, applicationName: 'Sub2API Monitor', applicationVersion: '1.0.0',
    applicationIcon: Container(width: 48, height: 48, decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(ctx).colorScheme.outline)),
        child: Center(child: Text('S2', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(ctx).colorScheme.primary)))),
  );
}

class _Tile extends StatelessWidget {
  final IconData icon; final String title; final ColorScheme cs; final VoidCallback onTap;
  const _Tile({required this.icon, required this.title, required this.cs, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 2), child: ListTile(
    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: cs.onSurfaceVariant)),
    title: Text(title, style: TextStyle(fontSize: 14, color: cs.onSurface)),
    trailing: Icon(Icons.chevron_right, size: 16, color: cs.onSurfaceVariant),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 4), onTap: onTap,
  ));
}
