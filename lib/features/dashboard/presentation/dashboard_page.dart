import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../domain/entities/dashboard_data.dart';
import '../domain/providers/dashboard_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/usage_chart.dart';
import '../widgets/top_models_chart.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.space_dashboard, size: 18, color: cs.primary)),
          const SizedBox(width: 10),
          Text('Sub2API 监控', style: TextStyle(color: cs.onSurface)),
        ]),
        actions: [
          IconButton(icon: Icon(Icons.refresh, size: 20, color: cs.onSurfaceVariant), onPressed: () => ref.read(dashboardProvider.notifier).refresh()),
          IconButton(icon: Icon(Icons.settings_outlined, size: 20, color: cs.onSurfaceVariant), onPressed: () => context.push('/settings')),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
        error: (err, _) => _ErrorView(error: err.toString(), onRetry: () => ref.read(dashboardProvider.notifier).refresh()),
        data: (d) => RefreshIndicator(
          color: cs.primary,
          backgroundColor: cs.surfaceContainer,
          onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: d.isAdmin ? _admin(context, d, cs) : _user(context, d, cs),
          ),
        ),
      ),
    );
  }

  List<Widget> _admin(BuildContext context, DashboardData d, ColorScheme cs) {
    final w = MediaQuery.sizeOf(context).width;
    final cols = w >= 800 ? 4 : (w >= 500 ? 3 : 2);
    return [
      _SystemStrip(d: d, cs: cs), const SizedBox(height: 20),
      _Label(text: '核心统计', cs: cs), const SizedBox(height: 10),
      ..._grid(cols, [
        StatCard(title: 'API Keys', value: _fmt(d.totalApiKeys), icon: Icons.vpn_key, color: cs.secondary, subtitle: '${d.activeApiKeys} 活跃'),
        StatCard(title: '服务账号', value: _fmt(d.totalAccounts), icon: Icons.dns, color: cs.tertiary,
            subtitle: '${d.normalAccounts} 正常 · ${d.errorAccounts} 异常',
            subtitleColor: d.errorAccounts > 0 ? cs.error : cs.tertiary),
        StatCard(title: '今日请求', value: _fmt(d.todayRequests), icon: Icons.trending_up, color: cs.primary,
            subtitle: '累计 ${_fmt(d.totalRequests)}'),
        StatCard(title: '今日新增用户', value: '+${_fmt(d.todayNewUsers)}', icon: Icons.person_add, color: cs.secondary,
            valueColor: cs.tertiary, subtitle: '累计 ${_fmt(d.totalUsers)}'),
      ]),
      const SizedBox(height: 22), _Label(text: 'Token 使用', cs: cs), const SizedBox(height: 10),
      ..._grid(cols, [
        StatCard(title: '今日 Token', value: _tokens(d.todayTokens), icon: Icons.bolt, color: cs.primary,
            subtitle: '\$${_cost(d.todayActualCost)} 实扣 / \$${_cost(d.todayCost)} 标准'),
        StatCard(title: '累计 Token', value: _tokens(d.totalTokens), icon: Icons.storage, color: cs.secondary,
            subtitle: '\$${_cost(d.totalActualCost)} 实扣'),
        StatCard(title: 'RPM / TPM', value: _tokens(d.rpm), icon: Icons.speed, color: cs.tertiary,
            subtitle: '${_tokens(d.tpm)} TPM'),
        StatCard(title: '平均响应', value: _dur(d.averageDurationMs), icon: Icons.timer, color: cs.error,
            subtitle: '${d.activeUsers} 活跃用户'),
      ]),
      if (d.dailyUsage.isNotEmpty) ...[const SizedBox(height: 24), _Label(text: '用量趋势', cs: cs), const SizedBox(height: 10), UsageChart(data: d.dailyUsage)],
      if (d.topModels.isNotEmpty) ...[const SizedBox(height: 24), _Label(text: '模型分布', cs: cs), const SizedBox(height: 10), TopModelsChart(models: d.topModels)],
    ];
  }

  List<Widget> _user(BuildContext context, DashboardData d, ColorScheme cs) => [
    _BalanceCard(balance: d.totalBalance, cs: cs), const SizedBox(height: 20),
    _Label(text: '用量总览', cs: cs), const SizedBox(height: 10),
    ..._grid(2, [
      StatCard(title: '今日', value: '\$${d.todayUsage.toStringAsFixed(2)}', icon: Icons.today, color: cs.primary),
      StatCard(title: '本周', value: '\$${d.weekUsage.toStringAsFixed(2)}', icon: Icons.date_range, color: cs.secondary),
      StatCard(title: '本月', value: '\$${d.monthUsage.toStringAsFixed(2)}', icon: Icons.calendar_month, color: cs.tertiary),
      StatCard(title: '请求数', value: _fmt(d.totalRequests), icon: Icons.send, color: cs.primary),
    ]),
    if (d.dailyUsage.isNotEmpty) ...[const SizedBox(height: 24), _Label(text: '用量趋势', cs: cs), const SizedBox(height: 10), UsageChart(data: d.dailyUsage)],
    if (d.topModels.isNotEmpty) ...[const SizedBox(height: 24), _Label(text: '热门模型', cs: cs), const SizedBox(height: 10), TopModelsChart(models: d.topModels)],
  ];

  List<Widget> _grid(int cols, List<Widget> cards) {
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += cols) {
      final children = <Widget>[];
      for (var j = 0; j < cols; j++) {
        final idx = i + j;
        if (j > 0) children.add(const SizedBox(width: 10));
        children.add(Expanded(child: idx < cards.length ? cards[idx] : const SizedBox()));
      }
      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: children));
      if (i + cols < cards.length) rows.add(const SizedBox(height: 10));
    }
    return rows;
  }

  String _fmt(int v) { if (v >= 1000000000) return '${(v/1000000000).toStringAsFixed(1)}B'; if (v >= 1000000) return '${(v/1000000).toStringAsFixed(1)}M'; if (v >= 1000) return '${(v/1000).toStringAsFixed(1)}K'; return v.toString(); }
  String _tokens(int v) { if (v >= 1000000000) return '${(v/1000000000).toStringAsFixed(2)}B'; if (v >= 1000000) return '${(v/1000000).toStringAsFixed(2)}M'; if (v >= 1000) return '${(v/1000).toStringAsFixed(1)}K'; return v.toString(); }
  String _cost(double v) { if (v >= 1000) return '${(v/1000).toStringAsFixed(2)}K'; if (v >= 1) return v.toStringAsFixed(2); return v.toStringAsFixed(4); }
  String _dur(double ms) { if (ms >= 1000) return '${(ms/1000).toStringAsFixed(1)}s'; return '${ms.round()}ms'; }
}

class _SystemStrip extends StatelessWidget {
  final DashboardData d;
  final ColorScheme cs;
  const _SystemStrip({required this.d, required this.cs});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(10), border: Border.all(color: cs.outline)),
    child: Row(children: [
      _Dot(color: cs.primary, label: '在线', cs: cs),
      const SizedBox(width: 14),
      _Dot(color: d.errorAccounts > 0 ? cs.error : cs.primary, label: '${d.errorAccounts} 异常', cs: cs),
      const SizedBox(width: 14),
      _Dot(color: d.ratelimitAccounts > 0 ? cs.secondary : cs.primary, label: '${d.ratelimitAccounts} 限速', cs: cs),
      const Spacer(),
      Text('UPTIME ${_uptime(d.uptime)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant, fontFamily: 'JetBrainsMono')),
    ]),
  );
  String _uptime(int s) { final h = s~/3600; final m = (s%3600)~/60; return h>0 ? '${h}h${m}m' : '${m}m'; }
}

class _Dot extends StatelessWidget {
  final Color color; final String label; final ColorScheme cs;
  const _Dot({required this.color, required this.label, required this.cs});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)])),
    const SizedBox(width: 5),
    Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
  ]);
}

class _Label extends StatelessWidget {
  final String text; final ColorScheme cs;
  const _Label({required this.text, required this.cs});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 3, height: 14, decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant, letterSpacing: 0.5)),
  ]);
}

class _ErrorView extends StatelessWidget {
  final String error; final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cs.error.withValues(alpha: 0.08), shape: BoxShape.circle), child: Icon(Icons.error_outline, size: 32, color: cs.error)),
      const SizedBox(height: 16), Text('加载失败', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
      const SizedBox(height: 6), Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Text(error, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))),
      const SizedBox(height: 16), ElevatedButton(onPressed: onRetry, child: const Text('重试')),
    ]));
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance; final ColorScheme cs;
  const _BalanceCard({required this.balance, required this.cs});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: cs.outline),
      boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.account_balance_wallet, size: 16, color: cs.primary)),
        const SizedBox(width: 10),
        Text('账号余额', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        const Spacer(),
        Text('USD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant, letterSpacing: 1)),
      ]),
      const SizedBox(height: 14),
      Text('\$${balance.toStringAsFixed(4)}', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, fontFamily: 'JetBrainsMono', color: cs.primary, letterSpacing: -0.5)),
    ]),
  );
}
