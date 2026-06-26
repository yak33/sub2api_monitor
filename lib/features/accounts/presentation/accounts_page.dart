import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../domain/entities/admin_account.dart';
import '../domain/providers/accounts_provider.dart';

class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});
  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  static const _platforms = [
    {'label': '全部', 'value': null}, {'label': 'OpenAI', 'value': 'openai'}, {'label': 'Anthropic', 'value': 'anthropic'},
    {'label': 'Gemini', 'value': 'gemini'}, {'label': 'Antigravity', 'value': 'antigravity'},
  ];
  static const _statuses = [
    {'label': '全部', 'value': null}, {'label': '正常', 'value': 'active'}, {'label': '错误', 'value': 'error'},
    {'label': '限速', 'value': 'ratelimit'}, {'label': '过载', 'value': 'overload'}, {'label': '停用', 'value': 'inactive'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(accountsListProvider);
    final n = ref.read(accountsListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('账号管理'),
        actions: [if (state.isLoading) const Padding(padding: EdgeInsets.only(right: 14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))],
      ),
      body: RefreshIndicator(
        color: cs.primary, backgroundColor: cs.surfaceContainer, onRefresh: n.refresh,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ChipRow(label: '平台', options: _platforms, selected: state.filterPlatform, onChanged: n.filterByPlatform, cs: cs),
            const SizedBox(height: 4),
            _ChipRow(label: '状态', options: _statuses, selected: state.filterStatus, onChanged: n.filterByStatus, cs: cs),
            const SizedBox(height: 4),
          ])),
          if (state.error != null) SliverToBoxAdapter(child: _Err(msg: state.error!, onRetry: n.refresh, cs: cs))
          else if (state.items.isEmpty && !state.isLoading) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: Text('暂无账号', style: TextStyle(fontSize: 14)))))
          else SliverList(delegate: SliverChildBuilderDelegate((_, i) => _Card(account: state.items[i], cs: cs,
            onTap: () => context.pushNamed('accountEdit', extra: state.items[i]),
            onTest: () => _test(n, state.items[i]),
            onClearError: () => n.clearError(state.items[i].id),
            onRecover: () => n.recoverState(state.items[i].id),
            onRefresh: () => n.refreshAccount(state.items[i].id),
            onDelete: () => _del(context, n, state.items[i]),
          ), childCount: state.items.length)),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ]),
      ),
    );
  }

  Future<void> _test(AccountsListNotifier n, AdminAccount a) async {
    try { await n.testAccount(a.id); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${a.name} 连通正常'))); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('测试失败: $e'))); }
  }
  void _del(BuildContext ctx, AccountsListNotifier n, AdminAccount a) => showDialog(context: ctx, builder: (c) => AlertDialog(
    title: const Text('删除账号'), content: Text('确定要删除 "${a.name}" 吗？'),
    actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('取消')), TextButton(onPressed: () async { await n.deleteAccount(a.id); if (c.mounted) Navigator.pop(c); }, child: const Text('删除', style: TextStyle(color: Color(0xFFD32F2F))))],
  ));
}

class _ChipRow extends StatelessWidget {
  final String label; final List<Map<String, dynamic>> options; final String? selected; final ValueChanged<String?> onChanged; final ColorScheme cs;
  const _ChipRow({required this.label, required this.options, required this.selected, required this.onChanged, required this.cs});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), child: Row(children: [
    SizedBox(width: 32, child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant, letterSpacing: 0.5))),
    Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: options.map((o) {
      final v = o['value'] as String?; final on = selected == v;
      return Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(
        label: Text(o['label'] as String, style: TextStyle(fontSize: 11, fontWeight: on ? FontWeight.w600 : FontWeight.w500, color: on ? cs.primary : cs.onSurfaceVariant)),
        selected: on, onSelected: (_) => onChanged(v), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact,
        backgroundColor: cs.surfaceContainerLow, selectedColor: cs.primary.withValues(alpha: 0.15), checkmarkColor: cs.primary,
        side: BorderSide(color: on ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant),
      ));
    }).toList()))),
  ]));
}

class _Err extends StatelessWidget {
  final String msg; final VoidCallback onRetry; final ColorScheme cs;
  const _Err({required this.msg, required this.onRetry, required this.cs});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(20), child: Column(children: [
    Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: cs.error.withValues(alpha: 0.08), shape: BoxShape.circle), child: Icon(Icons.error_outline, size: 28, color: cs.error)),
    const SizedBox(height: 10), Text(msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
    const SizedBox(height: 10), ElevatedButton(onPressed: onRetry, child: const Text('重试')),
  ]));
}

class _Card extends StatelessWidget {
  final AdminAccount account; final ColorScheme cs;
  final VoidCallback onTap, onTest, onClearError, onRecover, onRefresh, onDelete;
  const _Card({required this.account, required this.cs, required this.onTap, required this.onTest, required this.onClearError, required this.onRecover, required this.onRefresh, required this.onDelete});

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5), child: GestureDetector(
    onTap: onTap,
    child: Container(
    padding: const EdgeInsets.all(14),
    decoration: AppTheme.cardDecoration(cs),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(account.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface), overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 6), _Plat(p: account.platform), const SizedBox(width: 6), _Sta(s: account.status, cs: cs),
        PopupMenuButton<String>(padding: EdgeInsets.zero, iconSize: 18, color: cs.surfaceContainerHigh, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: cs.outlineVariant)),
          onSelected: (a) { switch(a){ case 'test': onTest(); case 'clear': onClearError(); case 'recover': onRecover(); case 'refresh': onRefresh(); case 'delete': onDelete(); } },
          itemBuilder: (_) => [
            _pi(Icons.wifi_tethering, '测试连通', 'test', cs), _pi(Icons.clear_all, '清除错误', 'clear', cs),
            _pi(Icons.restart_alt, '恢复状态', 'recover', cs), _pi(Icons.refresh, '刷新账号', 'refresh', cs),
            const PopupMenuDivider(), _pi(Icons.delete_outline, '删除', 'delete', cs, danger: true),
          ],
        ),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 4, children: [
        _Tag(icon: Icons.category, text: account.type, cs: cs),
        _Tag(icon: Icons.swap_vert, text: '${account.currentConcurrency}/${account.concurrency}', cs: cs),
        if (account.baseRpm != null) _Tag(icon: Icons.speed, text: '${account.baseRpm} RPM', cs: cs),
        _Tag(icon: Icons.low_priority, text: 'P${account.priority}', cs: cs),
      ]),
      if (account.quotaDailyUsed != null && account.quotaDailyLimit != null) ...[const SizedBox(height: 8), _QBar(label: '日', used: account.quotaDailyUsed!, limit: account.quotaDailyLimit!, cs: cs)],
      if (account.errorMessage != null && account.errorMessage!.isNotEmpty) ...[const SizedBox(height: 6), Text(account.errorMessage!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: cs.error))],
    ]),
  )));

  static PopupMenuItem<String> _pi(IconData icon, String label, String value, ColorScheme cs, {bool danger = false}) {
    final c = danger ? cs.error : cs.onSurfaceVariant;
    return PopupMenuItem(value: value, height: 36, child: Row(children: [Icon(icon, size: 15, color: c), const SizedBox(width: 8), Text(label, style: TextStyle(fontSize: 12, color: c))]));
  }
}

class _Plat extends StatelessWidget {
  final String p; const _Plat({required this.p});
  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch(p.toLowerCase()) {
      'openai'||'azure' => (Icons.open_in_new, AppTheme.openaiGreen), 'anthropic' => (Icons.psychology, AppTheme.anthropicOrange),
      'gemini' => (Icons.auto_awesome, AppTheme.geminiBlue), 'antigravity' => (Icons.rocket, AppTheme.antigravityPurple),
      _ => (Icons.cloud, const Color(0xFF636E72)),
    };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 10, color: color), const SizedBox(width: 3), Text(p, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color))]));
  }
}

class _Sta extends StatelessWidget {
  final String s; final ColorScheme cs;
  const _Sta({required this.s, required this.cs});
  @override
  Widget build(BuildContext context) {
    final (c, l) = switch(s) { 'active' => (cs.primary, '正常'), 'error' => (cs.error, '错误'), 'ratelimit' => (cs.secondary, '限速'), 'overload' => (const Color(0xFFE17055), '过载'), 'inactive' => (cs.onSurfaceVariant, '停用'), _ => (cs.onSurfaceVariant, s) };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(l, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c)));
  }
}

class _Tag extends StatelessWidget {
  final IconData icon; final String text; final ColorScheme cs;
  const _Tag({required this.icon, required this.text, required this.cs});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 10, color: cs.onSurfaceVariant), const SizedBox(width: 3), Text(text, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant))]));
}

class _QBar extends StatelessWidget {
  final String label; final double used, limit; final ColorScheme cs;
  const _QBar({required this.label, required this.used, required this.limit, required this.cs});
  @override
  Widget build(BuildContext context) {
    final pct = limit > 0 ? (used/limit).clamp(0.0, 1.0) : 0.0;
    return Row(children: [
      SizedBox(width: 20, child: Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant))), const SizedBox(width: 6),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: pct, minHeight: 4, backgroundColor: cs.outlineVariant, valueColor: AlwaysStoppedAnimation(pct > 0.8 ? cs.secondary : cs.primary)))),
      const SizedBox(width: 6), Text('\$${used.toStringAsFixed(1)}/\$${limit.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
    ]);
  }
}
