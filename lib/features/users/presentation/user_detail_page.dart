import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/admin_user.dart';
import '../domain/providers/users_provider.dart';

class UserDetailPage extends ConsumerWidget {
  final int userId;
  const UserDetailPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final userAsync = ref.watch(adminUserDetailProvider(userId));
    final usageAsync = ref.watch(adminUserUsageProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('用户详情')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 16), Text(err.toString()), const SizedBox(height: 16),
          ElevatedButton(onPressed: () => ref.invalidate(adminUserDetailProvider(userId)), child: const Text('重试')),
        ])),
        data: (user) => RefreshIndicator(
          onRefresh: () async { ref.invalidate(adminUserDetailProvider(userId)); ref.invalidate(adminUserUsageProvider(userId)); },
          child: ListView(padding: const EdgeInsets.all(16), children: [
            _Header(user: user, cs: cs), const SizedBox(height: 16),
            _Info(user: user, cs: cs), const SizedBox(height: 16),
            _Usage(usageAsync: usageAsync, cs: cs),
          ]),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AdminUser user; final ColorScheme cs;
  const _Header({required this.user, required this.cs});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.outline)),
    child: Column(children: [
      CircleAvatar(
        radius: 36,
        backgroundColor: cs.primary.withValues(alpha: 0.15),
        child: Text((user.email.isEmpty ? '?' : user.email)[0].toUpperCase(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: cs.primary)),
      ),
      const SizedBox(height: 12),
      Text(user.username.isEmpty ? user.email : user.username, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
      const SizedBox(height: 4),
      Text(user.email, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        if (user.isAdmin) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text('管理员', style: TextStyle(fontSize: 11, color: cs.primary))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: (user.isActive ? cs.primary : cs.onSurfaceVariant).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(user.isActive ? '活跃' : '停用', style: TextStyle(fontSize: 11, color: user.isActive ? cs.primary : cs.onSurfaceVariant))),
      ]),
    ]),
  );
}

class _Info extends StatelessWidget {
  final AdminUser user; final ColorScheme cs;
  const _Info({required this.user, required this.cs});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.outlineVariant)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('账号信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
      const SizedBox(height: 12),
      _Row(label: '用户 ID', value: '${user.id}', cs: cs),
      _Row(label: '余额', value: '\$${user.balance.toStringAsFixed(4)}', cs: cs),
      _Row(label: '累计充值', value: '\$${user.totalRecharged.toStringAsFixed(2)}', cs: cs),
      _Row(label: '并发', value: user.currentConcurrency != null ? '${user.currentConcurrency}/${user.concurrency}' : '${user.concurrency}', cs: cs),
      if (user.rpmLimit > 0) _Row(label: 'RPM 限制', value: '${user.rpmLimit}', cs: cs),
      _Row(label: '角色', value: user.isAdmin ? '管理员' : '普通用户', cs: cs),
      _Row(label: '状态', value: user.isActive ? '活跃' : '停用', cs: cs),
      if (user.lastActiveAt != null) _Row(label: '最后活跃', value: _fmt(user.lastActiveAt!), cs: cs),
      if (user.createdAt != null) _Row(label: '创建时间', value: _fmt(user.createdAt!), cs: cs),
      if (user.notes.isNotEmpty) ...[Divider(height: 24, color: cs.outlineVariant), Text('备注', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)), const SizedBox(height: 4), Text(user.notes, style: TextStyle(fontSize: 14, color: cs.onSurface))],
    ]),
  );

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}

class _Row extends StatelessWidget {
  final String label, value; final ColorScheme cs;
  const _Row({required this.label, required this.value, required this.cs});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
    Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
  ]));
}

class _Usage extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> usageAsync; final ColorScheme cs;
  const _Usage({required this.usageAsync, required this.cs});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.outlineVariant)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('用量统计（本月）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
      const SizedBox(height: 12),
      usageAsync.when(
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
        error: (e, _) => Text('加载失败: $e', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        data: (data) => _Grid(data: data, cs: cs),
      ),
    ]),
  );
}

class _Grid extends StatelessWidget {
  final Map<String, dynamic> data; final ColorScheme cs;
  const _Grid({required this.data, required this.cs});

  @override
  Widget build(BuildContext context) {
    final requests = _n(data, ['requests', 'total_requests']);
    final tokens = _n(data, ['total_tokens', 'tokens']);
    final cost = _d(data, ['total_cost', 'cost']);
    final inputTokens = _n(data, ['input_tokens', 'total_input_tokens']);
    final outputTokens = _n(data, ['output_tokens', 'total_output_tokens']);
    return Column(children: [
      Row(children: [Expanded(child: _Tile(label: '请求数', value: _f(requests), color: cs.primary, cs: cs)), const SizedBox(width: 12), Expanded(child: _Tile(label: '总 Token', value: _f(tokens), color: cs.secondary, cs: cs))]),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: _Tile(label: '输入 Token', value: _f(inputTokens), color: cs.tertiary, cs: cs)), const SizedBox(width: 12), Expanded(child: _Tile(label: '输出 Token', value: _f(outputTokens), color: cs.primary, cs: cs))]),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: _Tile(label: '消费', value: '\$${cost.toStringAsFixed(2)}', color: cs.error, cs: cs))]),
    ]);
  }

  int _n(Map<String, dynamic> j, List<String> ks) { for (final k in ks) { final v = j[k]; if (v is num) return v.toInt(); } return 0; }
  double _d(Map<String, dynamic> j, List<String> ks) { for (final k in ks) { final v = j[k]; if (v is num) return v.toDouble(); } return 0; }
  String _f(int v) { if (v>=1000000000) return '${(v/1000000000).toStringAsFixed(2)}B'; if (v>=1000000) return '${(v/1000000).toStringAsFixed(2)}M'; if (v>=1000) return '${(v/1000).toStringAsFixed(2)}K'; return '$v'; }
}

class _Tile extends StatelessWidget {
  final String label, value; final Color color; final ColorScheme cs;
  const _Tile({required this.label, required this.value, required this.color, required this.cs});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
    ]),
  );
}
