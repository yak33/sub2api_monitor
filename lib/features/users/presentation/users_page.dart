import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../domain/entities/admin_user.dart';
import '../domain/providers/users_provider.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final _searchController = TextEditingController();
  String _statusFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(usersListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(context, ref),
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          // ── 搜索 + 过滤栏 ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜索邮箱 / 用户名',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(usersListProvider.notifier).search('');
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (v) => ref.read(usersListProvider.notifier).search(v),
                  ),
                ),
                const SizedBox(width: 12),
                _StatusFilterChip(
                  value: _statusFilter,
                  onChanged: (v) {
                    setState(() => _statusFilter = v);
                    ref.read(usersListProvider.notifier).filterByStatus(v);
                  },
                ),
              ],
            ),
          ),
          // ── 列表 ──
          Expanded(child: _buildBody(context, ref, state)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    UsersListState state,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return _ErrorView(
        error: state.error!,
        onRetry: () => ref.read(usersListProvider.notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('暂无用户', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(usersListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.items.length + 1,
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return _PaginationBar(
              state: state,
              onPage: (p) => ref.read(usersListProvider.notifier).goToPage(p),
            );
          }
          return _UserCard(
            user: state.items[index],
            onTap: () => context.push('/users/${state.items[index].id}'),
            onEdit: () => _showFormDialog(context, ref, user: state.items[index]),
            onBalance: () => _showBalanceDialog(context, ref, state.items[index]),
            onDelete: () => _confirmDelete(context, ref, state.items[index]),
          );
        },
      ),
    );
  }

  void _showFormDialog(BuildContext context, WidgetRef ref, {AdminUser? user}) {
    showDialog(
      context: context,
      builder: (_) => _UserFormDialog(user: user),
    );
  }

  void _showBalanceDialog(BuildContext context, WidgetRef ref, AdminUser user) {
    showDialog(
      context: context,
      builder: (_) => _BalanceDialog(user: user),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AdminUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除用户'),
        content: Text('确定删除用户 ${user.email} 吗？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(usersListProvider.notifier).deleteUser(user.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已删除')),
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
            child: Text('删除', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
//  用户卡片
// ════════════════════════════════════════════════════

class _UserCard extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onBalance;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onEdit,
    required this.onBalance,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: (user.isAdmin ? AppTheme.warning : AppTheme.primary)
                          .withValues(alpha: 0.15),
                      child: Text(
                        (user.email.isEmpty ? '?' : user.email)[0].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: user.isAdmin ? AppTheme.warning : AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username.isEmpty ? user.email : user.username,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _RoleStatusBadge(user: user),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MetricChip(
                      label: '余额',
                      value: '\$${user.balance.toStringAsFixed(2)}',
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 8),
                    _MetricChip(
                      label: '并发',
                      value: user.currentConcurrency != null
                          ? '${user.currentConcurrency}/${user.concurrency}'
                          : '${user.concurrency}',
                      color: AppTheme.info,
                    ),
                    const SizedBox(width: 8),
                    if (user.rpmLimit > 0)
                      _MetricChip(
                        label: 'RPM',
                        value: '${user.rpmLimit}',
                        color: AppTheme.warning,
                      ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      padding: EdgeInsets.zero,
                      onSelected: (v) {
                        switch (v) {
                          case 'edit':
                            onEdit();
                          case 'balance':
                            onBalance();
                          case 'delete':
                            onDelete();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('编辑')),
                        PopupMenuItem(value: 'balance', child: Text('调整余额')),
                        PopupMenuItem(value: 'delete', child: Text('删除')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleStatusBadge extends StatelessWidget {
  final AdminUser user;

  const _RoleStatusBadge({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.isAdmin) {
      return _Badge(label: '管理员', color: AppTheme.warning);
    }
    return _Badge(
      label: user.isActive ? '活跃' : '停用',
      color: user.isActive ? AppTheme.success : Colors.grey,
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
//  状态过滤 Chip
// ════════════════════════════════════════════════════

class _StatusFilterChip extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusFilterChip({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (_) => const [
        PopupMenuItem(value: '', child: Text('全部状态')),
        PopupMenuItem(value: 'active', child: Text('活跃')),
        PopupMenuItem(value: 'disabled', child: Text('停用')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, size: 18, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              value.isEmpty ? '状态' : (value == 'active' ? '活跃' : '停用'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
//  分页栏
// ════════════════════════════════════════════════════

class _PaginationBar extends StatelessWidget {
  final UsersListState state;
  final ValueChanged<int> onPage;

  const _PaginationBar({required this.state, required this.onPage});

  @override
  Widget build(BuildContext context) {
    if (state.pages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: state.page > 1 ? () => onPage(state.page - 1) : null,
          ),
          Text('${state.page} / ${state.pages}', style: Theme.of(context).textTheme.bodyMedium),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.page < state.pages ? () => onPage(state.page + 1) : null,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
//  创建 / 编辑对话框
// ════════════════════════════════════════════════════

class _UserFormDialog extends ConsumerStatefulWidget {
  final AdminUser? user;

  const _UserFormDialog({this.user});

  @override
  ConsumerState<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<_UserFormDialog> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _concurrencyCtrl;
  late final TextEditingController _rpmCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _notesCtrl;
  String _status = 'active';
  bool _saving = false;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _passwordCtrl = TextEditingController();
    _usernameCtrl = TextEditingController(text: u?.username ?? '');
    _concurrencyCtrl = TextEditingController(text: '${u?.concurrency ?? 1}');
    _rpmCtrl = TextEditingController(text: '${u?.rpmLimit ?? 0}');
    _balanceCtrl = TextEditingController(text: u != null ? u.balance.toStringAsFixed(2) : '0');
    _notesCtrl = TextEditingController(text: u?.notes ?? '');
    _status = u?.status ?? 'active';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    _concurrencyCtrl.dispose();
    _rpmCtrl.dispose();
    _balanceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    if (!_isEdit && _passwordCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码至少 6 位'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        // 更新：指针字段语义，仅传需修改的字段
        final data = <String, dynamic>{
          'username': _usernameCtrl.text.trim(),
          'concurrency': int.tryParse(_concurrencyCtrl.text) ?? 1,
          'rpm_limit': int.tryParse(_rpmCtrl.text) ?? 0,
          'status': _status,
          'notes': _notesCtrl.text,
        };
        if (_passwordCtrl.text.isNotEmpty) data['password'] = _passwordCtrl.text;
        if (_balanceCtrl.text.isNotEmpty) {
          data['balance'] = double.tryParse(_balanceCtrl.text) ?? 0;
        }
        await ref.read(usersListProvider.notifier).updateUser(widget.user!.id, data);
      } else {
        await ref.read(usersListProvider.notifier).createUser({
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
          'username': _usernameCtrl.text.trim(),
          'concurrency': int.tryParse(_concurrencyCtrl.text) ?? 1,
          'rpm_limit': int.tryParse(_rpmCtrl.text) ?? 0,
          'balance': double.tryParse(_balanceCtrl.text) ?? 0,
          'notes': _notesCtrl.text,
        });
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? '已更新' : '已创建')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? '编辑用户' : '创建用户'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailCtrl,
              enabled: !_isEdit,
              decoration: const InputDecoration(labelText: '邮箱'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              decoration: InputDecoration(
                labelText: _isEdit ? '新密码（留空不改）' : '密码',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: '用户名'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _concurrencyCtrl,
                    decoration: const InputDecoration(labelText: '并发数'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _rpmCtrl,
                    decoration: const InputDecoration(labelText: 'RPM 限制'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _balanceCtrl,
              decoration: const InputDecoration(labelText: '余额', prefixText: '\$ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('状态', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('活跃'),
                  selected: _status == 'active',
                  onSelected: (_) => setState(() => _status = 'active'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('停用'),
                  selected: _status == 'disabled',
                  onSelected: (_) => setState(() => _status = 'disabled'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: '备注'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: _saving ? null : _submit, child: const Text('保存')),
      ],
    );
  }
}

// ════════════════════════════════════════════════════
//  余额调整对话框
// ════════════════════════════════════════════════════

class _BalanceDialog extends ConsumerStatefulWidget {
  final AdminUser user;

  const _BalanceDialog({required this.user});

  @override
  ConsumerState<_BalanceDialog> createState() => _BalanceDialogState();
}

class _BalanceDialogState extends ConsumerState<_BalanceDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  String _operation = 'add';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额'), backgroundColor: AppTheme.error),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(usersListProvider.notifier).adjustBalance(
            widget.user.id,
            balance: amount,
            operation: _operation,
            notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('余额已调整')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('调整余额'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('当前余额: \$${widget.user.balance.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              ChoiceChip(label: const Text('增加'), selected: _operation == 'add', onSelected: (_) => setState(() => _operation = 'add')),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('扣减'), selected: _operation == 'subtract', onSelected: (_) => setState(() => _operation = 'subtract')),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('设为'), selected: _operation == 'set', onSelected: (_) => setState(() => _operation = 'set')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            decoration: const InputDecoration(labelText: '金额', prefixText: '\$ '),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(labelText: '备注（可选）'),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: _saving ? null : _submit, child: const Text('确认')),
      ],
    );
  }
}

// ════════════════════════════════════════════════════
//  错误视图
// ════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppTheme.error),
          const SizedBox(height: 16),
          Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(error, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
