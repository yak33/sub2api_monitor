import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../domain/providers/user_balance_history_provider.dart';
import '../domain/entities/user_balance_history.dart';

/// 用户余额变动历史记录（充值记录）二级页面。
///
/// 展示充值、扣减、订阅变化、并发调整等历史足迹，
/// 包含变动金额、类型筛选、备注、系统汇总，且融入 M3 玻璃微光设计美学。
///
/// @author ZHANGCHAO
/// @date 2026/06/27
class UserBalanceHistoryPage extends ConsumerWidget {
  final int userId;

  const UserBalanceHistoryPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(userBalanceHistoryProvider(userId));
    final notifier = ref.read(userBalanceHistoryProvider(userId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('变动历史记录'),
        actions: [
          _TypeFilterButton(
            currentType: state.type,
            onChanged: notifier.filterByType,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: _buildContent(context, ref, state, notifier, cs),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    UserBalanceHistoryState state,
    UserBalanceHistoryNotifier notifier,
    ColorScheme cs,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return _buildErrorView(state.error!, notifier);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length + 2, // 1 for stats header, 1 for pagination bar
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildStatsHeader(context, state.totalRecharged, cs);
        }
        if (index == state.items.length + 1) {
          return _buildPaginationBar(context, state, notifier);
        }

        final item = state.items[index - 1];
        return _buildHistoryCard(context, item, cs);
      },
    );
  }

  /// 累计充值统计卡片（头部）
  Widget _buildStatsHeader(BuildContext context, double totalRecharged, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.15),
            cs.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: cs.primary.withValues(alpha: 0.15),
            child: Icon(Icons.account_balance_wallet, color: cs.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '累计充值',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${totalRecharged.toStringAsFixed(2)}',
                style: AppTheme.monoData(
                  size: 24,
                  color: cs.onSurface,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 余额变动历史记录卡片
  Widget _buildHistoryCard(BuildContext context, UserBalanceHistoryItem item, ColorScheme cs) {
    final isIncrease = item.value >= 0;
    final isConcurrency = item.type.contains('concurrency');
    final formattedValue = isIncrease
        ? '+${isConcurrency ? '' : '\$'}${item.value.toStringAsFixed(isConcurrency ? 0 : 4)}'
        : '${isConcurrency ? '' : '\$'}${item.value.toStringAsFixed(isConcurrency ? 0 : 4)}';

    final valueColor = isIncrease
        ? AppTheme.success
        : (isConcurrency ? AppTheme.warning : AppTheme.error);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTypeBadge(item.type, cs),
                Text(
                  formattedValue,
                  style: AppTheme.monoData(
                    size: 16,
                    color: valueColor,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (item.code.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.qr_code, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  SelectableText(
                    '兑换码: ${item.code}',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            if (item.notes.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.notes,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.4),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDateTime(item.createdAt),
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                ),
                if (item.status.isNotEmpty)
                  Text(
                    item.status == 'used' ? '已完成' : '未使用',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: item.status == 'used' ? AppTheme.success : AppTheme.info,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化时间为 yyyy-MM-dd HH:mm
  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final year = local.year;
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  /// 渲染变动类型的漂亮 Badge
  Widget _buildTypeBadge(String type, ColorScheme cs) {
    String label = '余额变动';
    Color color = AppTheme.info;

    switch (type) {
      case 'balance':
        label = '余额账户';
        color = AppTheme.info;
      case 'affiliate_balance':
        label = 'API余额';
        color = AppTheme.primary;
      case 'admin_balance':
        label = '系统调整';
        color = AppTheme.warning;
      case 'concurrency':
        label = '并发调整';
        color = AppTheme.accent;
      case 'admin_concurrency':
        label = '系统并发';
        color = AppTheme.accent;
      case 'subscription':
        label = '订阅变动';
        color = AppTheme.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  /// 分页条
  Widget _buildPaginationBar(
    BuildContext context,
    UserBalanceHistoryState state,
    UserBalanceHistoryNotifier notifier,
  ) {
    if (state.pages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: state.page > 1 ? () => notifier.goToPage(state.page - 1) : null,
          ),
          Text(
            '${state.page} / ${state.pages}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.page < state.pages ? () => notifier.goToPage(state.page + 1) : null,
          ),
        ],
      ),
    );
  }

  /// 错误视图
  Widget _buildErrorView(String error, UserBalanceHistoryNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text('数据加载失败', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: notifier.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 类型选择过滤器下拉组件
///
/// @author ZHANGCHAO
/// @date 2026/06/27
class _TypeFilterButton extends StatelessWidget {
  final String currentType;
  final ValueChanged<String> onChanged;

  const _TypeFilterButton({
    required this.currentType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, String> types = {
      '': '全部类型',
      'balance': '余额账户',
      'affiliate_balance': 'API余额',
      'admin_balance': '系统调整',
      'concurrency': '并发调整',
      'admin_concurrency': '系统并发',
      'subscription': '订阅变动',
    };

    return PopupMenuButton<String>(
      onSelected: onChanged,
      icon: const Icon(Icons.filter_list),
      tooltip: '筛选变动类型',
      itemBuilder: (_) => types.entries
          .map(
            (e) => PopupMenuItem(
              value: e.key,
              child: Row(
                children: [
                  if (currentType == e.key)
                    Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Text(e.value),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
