import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../domain/entities/admin_subscription.dart';
import '../domain/providers/subscriptions_provider.dart';

/// 订阅管理页面。
///
/// 管理员视角：查看全站订阅列表、按状态过滤、分配/延期/重置/撤销订阅。
class SubscriptionsPage extends ConsumerStatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  ConsumerState<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends ConsumerState<SubscriptionsPage> {
  static const _statusOptions = [
    {'label': '全部', 'value': null},
    {'label': '生效中', 'value': 'active'},
    {'label': '已过期', 'value': 'expired'},
    {'label': '已撤销', 'value': 'revoked'},
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionsListProvider);
    final notifier = ref.read(subscriptionsListProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('订阅管理'),
        actions: [
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 状态过滤栏
          _FilterBar(
            options: _statusOptions,
            selected: state.filterStatus,
            onChanged: notifier.filterByStatus,
          ),
          // 列表
          Expanded(
            child: _buildBody(state, notifier, theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignSheet(context, ref, notifier),
        icon: const Icon(Icons.add),
        label: const Text('分配订阅'),
      ),
    );
  }

  Widget _buildBody(
    SubscriptionsListState state,
    SubscriptionsListNotifier notifier,
    ThemeData theme,
  ) {
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(state.error!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: notifier.refresh, child: const Text('重试')),
          ],
        ),
      );
    }

    if (state.items.isEmpty && !state.isLoading) {
      return const Center(child: Text('暂无订阅记录', style: TextStyle(color: Color(0xFF636E72))));
    }

    final fmt = NumberFormat('#,##0.0000');

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: state.items.length,
        itemBuilder: (context, index) => _SubscriptionCard(
          sub: state.items[index],
          fmt: fmt,
          onExtend: () => _showExtendDialog(context, ref, notifier, state.items[index]),
          onResetQuota: () => _showResetQuotaDialog(context, ref, notifier, state.items[index]),
          onRevoke: () => _confirmRevoke(context, ref, notifier, state.items[index]),
        ),
      ),
    );
  }

  // ── 分配订阅 ──
  void _showAssignSheet(
      BuildContext context, WidgetRef ref, SubscriptionsListNotifier notifier) {
    final userIdCtrl = TextEditingController();
    final groupIdCtrl = TextEditingController();
    final daysCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('分配订阅', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: userIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '用户 ID *', hintText: '输入用户 ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: groupIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '分组 ID *', hintText: '输入分组 ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: daysCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '有效天数',
                hintText: '留空使用分组默认配置',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: '备注', hintText: '可选'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final uid = int.tryParse(userIdCtrl.text);
                final gid = int.tryParse(groupIdCtrl.text);
                if (uid == null || gid == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写有效的用户 ID 和分组 ID')),
                  );
                  return;
                }
                try {
                  await notifier.assign(
                    userId: uid,
                    groupId: gid,
                    validityDays: int.tryParse(daysCtrl.text),
                    notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('订阅分配成功')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('分配失败: $e'), backgroundColor: AppTheme.error),
                    );
                  }
                }
              },
              child: const Text('确认分配'),
            ),
          ],
        ),
      ),
    );
  }

  // ── 延期 ──
  void _showExtendDialog(BuildContext context, WidgetRef ref,
      SubscriptionsListNotifier notifier, AdminSubscription sub) {
    final daysCtrl = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('调整有效期'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('订阅 #${sub.id}',
                style: const TextStyle(color: Color(0xFF636E72), fontSize: 13)),
            if (sub.user != null)
              Text('用户: ${sub.user!.email}',
                  style: const TextStyle(color: Color(0xFF636E72), fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: daysCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '天数',
                hintText: '正数延长，负数缩短（±36500）',
                helperText: '当前到期: ${sub.expiresAt != null ? DateFormat('yyyy-MM-dd').format(sub.expiresAt!) : '永久'}',
                helperMaxLines: 2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              final days = int.tryParse(daysCtrl.text);
              if (days == null || days == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入有效天数')),
                );
                return;
              }
              try {
                await notifier.extend(sub.id, days);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('有效期已调整 ${days > 0 ? "+$days" : "$days"} 天')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('操作失败: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  // ── 重置配额 ──
  void _showResetQuotaDialog(BuildContext context, WidgetRef ref,
      SubscriptionsListNotifier notifier, AdminSubscription sub) {
    bool daily = false;
    bool weekly = false;
    bool monthly = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('重置用量额度'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('订阅 #${sub.id}',
                  style: const TextStyle(color: Color(0xFF636E72), fontSize: 13)),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: daily,
                onChanged: (v) => setDialogState(() => daily = v ?? false),
                title: const Text('日用量'),
                subtitle: Text('当前: \$${sub.dailyUsageUsd.toStringAsFixed(4)}'),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              CheckboxListTile(
                value: weekly,
                onChanged: (v) => setDialogState(() => weekly = v ?? false),
                title: const Text('周用量'),
                subtitle: Text('当前: \$${sub.weeklyUsageUsd.toStringAsFixed(4)}'),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              CheckboxListTile(
                value: monthly,
                onChanged: (v) => setDialogState(() => monthly = v ?? false),
                title: const Text('月用量'),
                subtitle: Text('当前: \$${sub.monthlyUsageUsd.toStringAsFixed(4)}'),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: (!daily && !weekly && !monthly)
                  ? null
                  : () async {
                      try {
                        await notifier.resetQuota(sub.id,
                            daily: daily, weekly: weekly, monthly: monthly);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('用量额度已重置')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('操作失败: $e'),
                                backgroundColor: AppTheme.error),
                          );
                        }
                      }
                    },
              child: const Text('确认重置'),
            ),
          ],
        ),
      ),
    );
  }

  // ── 撤销确认 ──
  void _confirmRevoke(BuildContext context, WidgetRef ref,
      SubscriptionsListNotifier notifier, AdminSubscription sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('撤销订阅'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要撤销订阅 #${sub.id} 吗？',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            if (sub.user != null) ...[
              const SizedBox(height: 4),
              Text('用户: ${sub.user!.email}',
                  style: const TextStyle(color: Color(0xFF636E72), fontSize: 13)),
            ],
            if (sub.group != null)
              Text('分组: ${sub.group!.name}',
                  style: const TextStyle(color: Color(0xFF636E72), fontSize: 13)),
            const SizedBox(height: 8),
            const Text('此操作不可逆', style: TextStyle(color: AppTheme.error, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              try {
                await notifier.revoke(sub.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('订阅已撤销')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('操作失败: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('确认撤销', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

// ── 过滤栏 ──
class _FilterBar extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _FilterBar({required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: options.map((opt) {
          final value = opt['value'] as String?;
          final isSelected = selected == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(opt['label'] as String),
              selected: isSelected,
              onSelected: (_) => onChanged(value),
              selectedColor: AppTheme.primary.withValues(alpha: 0.15),
              checkmarkColor: AppTheme.primary,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 订阅卡片 ──
class _SubscriptionCard extends StatelessWidget {
  final AdminSubscription sub;
  final NumberFormat fmt;
  final VoidCallback onExtend;
  final VoidCallback onResetQuota;
  final VoidCallback onRevoke;

  const _SubscriptionCard({
    required this.sub,
    required this.fmt,
    required this.onExtend,
    required this.onResetQuota,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部行：ID + 用户 + 状态
            Row(
              children: [
                Text('#${sub.id}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF636E72))),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sub.user?.email ?? sub.user?.username ?? '用户 #${sub.userId}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusBadge(status: sub.status),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  onSelected: (action) {
                    switch (action) {
                      case 'extend':
                        onExtend();
                      case 'reset':
                        onResetQuota();
                      case 'revoke':
                        onRevoke();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'extend', child: ListTile(
                      leading: Icon(Icons.schedule),
                      title: Text('调整有效期'),
                      dense: true,
                    )),
                    const PopupMenuItem(value: 'reset', child: ListTile(
                      leading: Icon(Icons.restart_alt),
                      title: Text('重置配额'),
                      dense: true,
                    )),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'revoke',
                      child: ListTile(
                        leading: const Icon(Icons.cancel, color: AppTheme.error),
                        title: const Text('撤销订阅', style: TextStyle(color: AppTheme.error)),
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 分组信息
            if (sub.group != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    _InfoChip(
                        icon: Icons.folder_outlined,
                        label: '${sub.group!.name} (${sub.group!.platform})'),
                  ],
                ),
              ),
            // 用量行
            _UsageRow(
              label: '日',
              used: sub.dailyUsageUsd,
              limit: sub.group?.dailyLimitUsd,
              fmt: fmt,
            ),
            _UsageRow(
              label: '周',
              used: sub.weeklyUsageUsd,
              limit: sub.group?.weeklyLimitUsd,
              fmt: fmt,
            ),
            _UsageRow(
              label: '月',
              used: sub.monthlyUsageUsd,
              limit: sub.group?.monthlyLimitUsd,
              fmt: fmt,
            ),
            const SizedBox(height: 6),
            // 底行：有效期 + 备注
            Row(
              children: [
                Icon(Icons.event, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    sub.hasExpiry
                        ? '到期 ${DateFormat('yyyy-MM-dd').format(sub.expiresAt!)}'
                        : '永久有效',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ),
                if (sub.notes.isNotEmpty)
                  Flexible(
                    child: Text(
                      sub.notes,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 状态徽章 ──
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'active' => (AppTheme.success, '生效中'),
      'expired' => (AppTheme.warning, '已过期'),
      'revoked' => (AppTheme.error, '已撤销'),
      'pending' => (AppTheme.info, '待生效'),
      _ => (const Color(0xFF636E72), status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── 信息标签 ──
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.primary)),
        ],
      ),
    );
  }
}

// ── 用量行 ──
class _UsageRow extends StatelessWidget {
  final String label;
  final double used;
  final double? limit;
  final NumberFormat fmt;

  const _UsageRow({
    required this.label,
    required this.used,
    required this.limit,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final hasLimit = limit != null && limit! > 0;
    final pct = hasLimit ? (used / limit!).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF636E72))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(
                  pct > 0.8 ? AppTheme.warning : AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              hasLimit ? '\$${fmt.format(used)} / \$${fmt.format(limit!)}' : '\$${fmt.format(used)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: pct > 0.8 ? AppTheme.warning : const Color(0xFF636E72),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
