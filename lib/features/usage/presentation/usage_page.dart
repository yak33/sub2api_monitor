import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../app/app_theme.dart';
import '../domain/entities/usage_log.dart';
import '../domain/providers/usage_provider.dart';

class UsagePage extends ConsumerWidget {
  const UsagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(usageLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('用量详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(usageLogsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('加载失败: $err')),
        data: (state) => _LogList(state: state),
      ),
    );
  }
}

class _LogList extends ConsumerWidget {
  final UsageLogsState state;

  const _LogList({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('暂无使用记录', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.logs.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.logs.length) {
          // 加载更多
          ref.read(usageLogsProvider.notifier).loadMore();
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final log = state.logs[index];
        return _UsageLogCard(log: log);
      },
    );
  }
}

class _UsageLogCard extends StatelessWidget {
  final UsageLog log;

  const _UsageLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 模型名 + 时间
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.model,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                timeago.format(log.createdAt, locale: 'zh'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Token 统计
          Row(
            children: [
              _TokenChip(label: '输入', value: _fmt(log.inputTokens), color: AppTheme.info),
              const SizedBox(width: 8),
              _TokenChip(label: '输出', value: _fmt(log.outputTokens), color: AppTheme.success),
              if (log.cacheReadTokens > 0) ...[
                const SizedBox(width: 8),
                _TokenChip(label: '缓存', value: _fmt(log.cacheReadTokens), color: AppTheme.accent),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // 费用 + 耗时
          Row(
            children: [
              Text(
                '\$${log.totalCost.toStringAsFixed(4)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
              ),
              const Spacer(),
              if (log.firstTokenMs != null)
                Text(
                  'TTFT ${log.firstTokenMs}ms',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(width: 12),
              Icon(log.stream ? Icons.stream : Icons.block, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                '${log.durationMs}ms',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _TokenChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TokenChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color)),
          const SizedBox(width: 3),
          Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
