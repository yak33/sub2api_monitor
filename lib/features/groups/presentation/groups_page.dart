import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../domain/entities/group.dart';
import '../domain/providers/groups_provider.dart';

/// 分组管理页面。
///
/// 采用 Material 3 "Dual-Plane Precision" 设计系统，
/// 包含卡片式指标概览、分页与平台/状态重置过滤，并提供专属倍率/RPM 调控入口。
///
/// @author ZHANGCHAO
/// @date 2026/06/27
class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});

  @override
  ConsumerState<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends ConsumerState<GroupsPage> {
  static const _platforms = [
    {'label': '全部', 'value': null},
    {'label': 'OpenAI', 'value': 'openai'},
    {'label': 'Anthropic', 'value': 'anthropic'},
    {'label': 'Gemini', 'value': 'gemini'},
    {'label': 'Antigravity', 'value': 'antigravity'},
  ];

  static const _statuses = [
    {'label': '全部', 'value': null},
    {'label': '正常', 'value': 'active'},
    {'label': '停用', 'value': 'inactive'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(groupsListProvider);
    final notifier = ref.read(groupsListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分组管理'),
        actions: [
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '创建分组',
            onPressed: () => context.pushNamed('groupEdit'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: cs.primary,
        backgroundColor: cs.surfaceContainer,
        onRefresh: notifier.refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChipRow(
                    label: '平台',
                    options: _platforms,
                    selected: state.filterPlatform,
                    onChanged: notifier.filterByPlatform,
                    cs: cs,
                  ),
                  const SizedBox(height: 4),
                  _ChipRow(
                    label: '状态',
                    options: _statuses,
                    selected: state.filterStatus,
                    onChanged: notifier.filterByStatus,
                    cs: cs,
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            if (state.error != null)
              SliverToBoxAdapter(
                child: _ErrorView(
                  msg: state.error!,
                  onRetry: notifier.refresh,
                  cs: cs,
                ),
              )
            else if (state.items.isEmpty && !state.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text('暂无分组数据', style: TextStyle(fontSize: 14)),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == state.items.length) {
                      return _PaginationBar(
                        page: state.page,
                        pages: state.pages,
                        onPage: notifier.goToPage,
                      );
                    }
                    final group = state.items[index];
                    return _GroupCard(
                      group: group,
                      cs: cs,
                      onEdit: () => context.pushNamed('groupEdit', extra: group),
                      onRateMultipliers: () => _showRateMultipliersDialog(context, ref, notifier, group),
                      onRpmOverrides: () => _showRpmOverridesDialog(context, ref, notifier, group),
                      onDelete: () => _confirmDelete(context, notifier, group),
                    );
                  },
                  childCount: state.items.length + 1,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  void _showRateMultipliersDialog(
    BuildContext context,
    WidgetRef ref,
    GroupsListNotifier notifier,
    AdminGroup group,
  ) {
    showDialog(
      context: context,
      builder: (_) => _RateMultipliersDialog(group: group, notifier: notifier),
    );
  }

  void _showRpmOverridesDialog(
    BuildContext context,
    WidgetRef ref,
    GroupsListNotifier notifier,
    AdminGroup group,
  ) {
    showDialog(
      context: context,
      builder: (_) => _RpmOverridesDialog(group: group, notifier: notifier),
    );
  }

  void _confirmDelete(BuildContext context, GroupsListNotifier notifier, AdminGroup group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除分组'),
        content: Text('确定要删除分组 "${group.name}" 吗？此操作不可逆。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await notifier.deleteGroup(group.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除成功')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('删除', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> options;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final ColorScheme cs;

  const _ChipRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: options.map((o) {
                  final v = o['value'] as String?;
                  final on = selected == v;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(
                        o['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                          color: on ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                      selected: on,
                      onSelected: (_) => onChanged(v),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: cs.surfaceContainerLow,
                      selectedColor: cs.primary.withValues(alpha: 0.15),
                      checkmarkColor: cs.primary,
                      side: BorderSide(
                        color: on ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  final ColorScheme cs;

  const _ErrorView({
    required this.msg,
    required this.onRetry,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.error.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 28, color: cs.error),
          ),
          const SizedBox(height: 10),
          Text(msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final AdminGroup group;
  final ColorScheme cs;
  final VoidCallback onEdit;
  final VoidCallback onRateMultipliers;
  final VoidCallback onRpmOverrides;
  final VoidCallback onDelete;

  const _GroupCard({
    required this.group,
    required this.cs,
    required this.onEdit,
    required this.onRateMultipliers,
    required this.onRpmOverrides,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = cs.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Material(
        color: isDark ? cs.surfaceContainerLow : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        shadowColor: Colors.black,
        elevation: isDark ? 2 : 0.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildPlatformTag(group.platform),
                    const SizedBox(width: 6),
                    _buildStatusTag(group.status),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      color: cs.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                      onSelected: (action) {
                        switch (action) {
                          case 'edit':
                            onEdit();
                          case 'rates':
                            onRateMultipliers();
                          case 'rpm':
                            onRpmOverrides();
                          case 'delete':
                            onDelete();
                        }
                      },
                      itemBuilder: (_) => [
                        _buildMenuItem(Icons.edit_outlined, '编辑配置', 'edit'),
                        _buildMenuItem(Icons.percent_outlined, '专属倍率', 'rates'),
                        _buildMenuItem(Icons.speed_outlined, '专属 RPM', 'rpm'),
                        const PopupMenuDivider(),
                        _buildMenuItem(Icons.delete_outline, '删除分组', 'delete', danger: true),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (group.description.isNotEmpty) ...[
                  Text(
                    group.description,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                ],
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _TagBadge(
                      icon: Icons.category_outlined,
                      text: group.isExclusive ? '专属分组' : '公开分组',
                      color: group.isExclusive ? AppTheme.warning : AppTheme.success,
                      cs: cs,
                    ),
                    _TagBadge(
                      icon: Icons.payments_outlined,
                      text: '倍率: ${group.rateMultiplier.toStringAsFixed(1)}x',
                      color: AppTheme.info,
                      cs: cs,
                    ),
                    _TagBadge(
                      icon: Icons.dns_outlined,
                      text: '账号: ${group.activeAccountCount}/${group.accountCount}',
                      color: AppTheme.primary,
                      cs: cs,
                    ),
                    if (group.rpmLimit > 0)
                      _TagBadge(
                        icon: Icons.speed_outlined,
                        text: 'RPM Limit: ${group.rpmLimit}',
                        color: AppTheme.accent,
                        cs: cs,
                      ),
                  ],
                ),
                if (group.dailyLimitUSD != null || group.weeklyLimitUSD != null || group.monthlyLimitUSD != null) ...[
                  const SizedBox(height: 10),
                  Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '额度限制:',
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                      Row(
                        children: [
                          if (group.dailyLimitUSD != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _TextLimitBadge(label: '日', value: group.dailyLimitUSD!, cs: cs),
                            ),
                          if (group.weeklyLimitUSD != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _TextLimitBadge(label: '周', value: group.weeklyLimitUSD!, cs: cs),
                            ),
                          if (group.monthlyLimitUSD != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _TextLimitBadge(label: '月', value: group.monthlyLimitUSD!, cs: cs),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    IconData icon,
    String label,
    String value, {
    bool danger = false,
  }) {
    final color = danger ? cs.error : cs.onSurfaceVariant;
    return PopupMenuItem(
      value: value,
      height: 36,
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildPlatformTag(String platform) {
    final (icon, color) = switch (platform.toLowerCase()) {
      'openai' => (Icons.open_in_new, AppTheme.openaiGreen),
      'anthropic' => (Icons.psychology, AppTheme.anthropicOrange),
      'gemini' => (Icons.auto_awesome, AppTheme.geminiBlue),
      'antigravity' => (Icons.rocket, AppTheme.antigravityPurple),
      _ => (Icons.cloud, const Color(0xFF636E72)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            platform,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    final active = status == 'active';
    final color = active ? AppTheme.success : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        active ? '正常' : '停用',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final ColorScheme cs;

  const _TagBadge({
    required this.icon,
    required this.text,
    required this.color,
    required this.cs,
  });

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
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _TextLimitBadge extends StatelessWidget {
  final String label;
  final double value;
  final ColorScheme cs;

  const _TextLimitBadge({required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: cs.outlineVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: \$${value.toStringAsFixed(0)}',
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int page;
  final int pages;
  final ValueChanged<int> onPage;

  const _PaginationBar({
    required this.page,
    required this.pages,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) {
    if (pages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: page > 1 ? () => onPage(page - 1) : null,
          ),
          Text('$page / $pages', style: Theme.of(context).textTheme.bodyMedium),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: page < pages ? () => onPage(page + 1) : null,
          ),
        ],
      ),
    );
  }
}

/// 专属倍率管理 Dialog。
class _RateMultipliersDialog extends ConsumerStatefulWidget {
  final AdminGroup group;
  final GroupsListNotifier notifier;

  const _RateMultipliersDialog({required this.group, required this.notifier});

  @override
  ConsumerState<_RateMultipliersDialog> createState() => _RateMultipliersDialogState();
}

class _RateMultipliersDialogState extends ConsumerState<_RateMultipliersDialog> {
  bool _loading = true;
  bool _saving = false;
  List<UserGroupRateEntry> _entries = [];

  final _userIdCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final client = ref.read(apiClientProvider);
      final list = await client.getGroupRateMultipliers(widget.group.id);
      if (mounted) {
        setState(() {
          _entries = list
              .where((e) => e != null)
              .map((e) => UserGroupRateEntry.fromJson(e as Map<String, dynamic>))
              .where((e) => e.rateMultiplier != null)
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final payload = _entries
          .map((e) => {
                'user_id': e.userId,
                'rate_multiplier': e.rateMultiplier ?? 1.0,
              })
          .toList();

      await widget.notifier.saveRateMultipliers(widget.group.id, payload);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('费率倍数保存成功')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addEntry() {
    final userId = int.tryParse(_userIdCtrl.text);
    final rate = double.tryParse(_rateCtrl.text);

    if (userId == null || rate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入合法的用户 ID 与倍数值'), backgroundColor: AppTheme.error),
      );
      return;
    }

    if (_entries.any((e) => e.userId == userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该用户已在列表中'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() {
      _entries.add(
        UserGroupRateEntry(
          userId: userId,
          userEmail: '用户 ID: $userId',
          userName: '',
          userNotes: '',
          userStatus: 'active',
          rateMultiplier: rate,
        ),
      );
      _userIdCtrl.clear();
      _rateCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text('【${widget.group.name}】专属倍数'),
      content: _loading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _userIdCtrl,
                            decoration: const InputDecoration(labelText: '用户 ID', isDense: true),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _rateCtrl,
                            decoration: const InputDecoration(labelText: '费率倍率', suffixText: 'x', isDense: true),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add),
                          onPressed: _addEntry,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('暂无专属费率限制', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _entries.length,
                        itemBuilder: (context, i) {
                          final item = _entries[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.userEmail.isNotEmpty ? item.userEmail : '用户 ID: ${item.userId}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('ID: ${item.userId}', style: const TextStyle(fontSize: 10)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${item.rateMultiplier}x',
                                  style: AppTheme.monoData(size: 13, color: cs.primary),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                                  onPressed: () => setState(() => _entries.removeAt(i)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        if (!_loading) ...[
          TextButton(
            onPressed: _saving
                ? null
                : () {
                    setState(() => _entries.clear());
                    _save();
                  },
            child: const Text('清空全部', style: TextStyle(color: AppTheme.error)),
          ),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存修改'),
          ),
        ],
      ],
    );
  }
}

/// 专属 RPM 管理 Dialog。
class _RpmOverridesDialog extends ConsumerStatefulWidget {
  final AdminGroup group;
  final GroupsListNotifier notifier;

  const _RpmOverridesDialog({required this.group, required this.notifier});

  @override
  ConsumerState<_RpmOverridesDialog> createState() => _RpmOverridesDialogState();
}

class _RpmOverridesDialogState extends ConsumerState<_RpmOverridesDialog> {
  bool _loading = true;
  bool _saving = false;
  List<UserGroupRateEntry> _entries = [];

  final _userIdCtrl = TextEditingController();
  final _rpmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _rpmCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final client = ref.read(apiClientProvider);
      final list = await client.getGroupRateMultipliers(widget.group.id);
      if (mounted) {
        setState(() {
          _entries = list
              .where((e) => e != null)
              .map((e) => UserGroupRateEntry.fromJson(e as Map<String, dynamic>))
              .where((e) => e.rpmOverride != null)
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final payload = _entries
          .map((e) => {
                'user_id': e.userId,
                'rpm_override': e.rpmOverride,
              })
          .toList();

      await widget.notifier.saveRpmOverrides(widget.group.id, payload);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RPM 限制保存成功')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addEntry() {
    final userId = int.tryParse(_userIdCtrl.text);
    final rpm = int.tryParse(_rpmCtrl.text);

    if (userId == null || rpm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入合法的用户 ID 与 RPM 限额'), backgroundColor: AppTheme.error),
      );
      return;
    }

    if (_entries.any((e) => e.userId == userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该用户已在列表中'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() {
      _entries.add(
        UserGroupRateEntry(
          userId: userId,
          userEmail: '用户 ID: $userId',
          userName: '',
          userNotes: '',
          userStatus: 'active',
          rpmOverride: rpm,
        ),
      );
      _userIdCtrl.clear();
      _rpmCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text('【${widget.group.name}】专属 RPM'),
      content: _loading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _userIdCtrl,
                            decoration: const InputDecoration(labelText: '用户 ID', isDense: true),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _rpmCtrl,
                            decoration: const InputDecoration(labelText: 'RPM 限额', isDense: true),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add),
                          onPressed: _addEntry,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('暂无专属 RPM 限制', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _entries.length,
                        itemBuilder: (context, i) {
                          final item = _entries[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.userEmail.isNotEmpty ? item.userEmail : '用户 ID: ${item.userId}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('ID: ${item.userId}', style: const TextStyle(fontSize: 10)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${item.rpmOverride} RPM',
                                  style: AppTheme.monoData(size: 13, color: cs.primary),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                                  onPressed: () => setState(() => _entries.removeAt(i)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        if (!_loading) ...[
          TextButton(
            onPressed: _saving
                ? null
                : () {
                    setState(() => _entries.clear());
                    _save();
                  },
            child: const Text('清空全部', style: TextStyle(color: AppTheme.error)),
          ),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存修改'),
          ),
        ],
      ],
    );
  }
}
