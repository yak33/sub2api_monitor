import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../groups/domain/entities/group.dart';
import '../domain/entities/admin_account.dart';
import '../domain/providers/accounts_provider.dart';

/// AI 账号编辑/新建页面。
///
/// 字段布局对齐 sub2api Web 管理端 `CreateAccountRequest` / `UpdateAccountRequest`，
/// 采用与 GroupEditPage 一致的路由跳转 + PopScope 防丢失模式。
///
/// @author ZHANGCHAO
/// @date 2026/06/27
class AccountEditPage extends ConsumerStatefulWidget {
  final AdminAccount? account;

  const AccountEditPage({super.key, this.account});

  @override
  ConsumerState<AccountEditPage> createState() => _AccountEditPageState();
}

class _AccountEditPageState extends ConsumerState<AccountEditPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _concurrencyCtrl;
  late final TextEditingController _priorityCtrl;
  late final TextEditingController _rateMultiplierCtrl;
  late final TextEditingController _loadFactorCtrl;

  String _platform = 'anthropic';
  String _type = 'oauth';
  String _status = 'active';
  bool _schedulable = true;
  bool _autoPauseOnExpired = false;
  DateTime? _expiresAt;

  // ── 分组关联 ──
  List<AdminGroup> _allGroups = [];
  Set<int> _selectedGroupIds = {};
  bool _loadingGroups = true;

  bool _saving = false;

  // ── 账号类型选项（对齐后端 binding:"oneof=..."）──
  static const _typeOptions = [
    ('oauth', 'OAuth'),
    ('setup-token', 'Setup Token'),
    ('apikey', 'API Key'),
    ('upstream', 'Upstream'),
    ('bedrock', 'Bedrock'),
    ('service_account', 'Service Account'),
  ];

  static const _platformOptions = [
    ('openai', 'OpenAI'),
    ('anthropic', 'Anthropic'),
    ('gemini', 'Gemini'),
    ('antigravity', 'Antigravity'),
    ('grok', 'Grok'),
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _notesCtrl = TextEditingController(text: a?.notes ?? '');
    _concurrencyCtrl = TextEditingController(text: '${a?.concurrency ?? 1}');
    _priorityCtrl = TextEditingController(text: '${a?.priority ?? 0}');
    _rateMultiplierCtrl = TextEditingController(text: '${a?.rateMultiplier ?? 1.0}');
    _loadFactorCtrl = TextEditingController(text: '${a?.loadFactor ?? 0}');

    if (a != null) {
      _platform = a.platform.toLowerCase();
      _type = a.type;
      _status = a.status;
      _schedulable = a.schedulable;
      _autoPauseOnExpired = a.autoPauseOnExpired;
      _expiresAt = a.expiresAt;
      _selectedGroupIds = a.groupIds.toSet();
    }

    _loadGroups();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _concurrencyCtrl.dispose();
    _priorityCtrl.dispose();
    _rateMultiplierCtrl.dispose();
    _loadFactorCtrl.dispose();
    super.dispose();
  }

  /// 拉取所有分组列表以供关联选择
  Future<void> _loadGroups() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.getAdminGroups(page: 1, pageSize: 1000);
      final data = (resp['data'] as Map<String, dynamic>?) ?? resp;
      final items = (data['items'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(AdminGroup.fromJson)
              .toList() ??
          const <AdminGroup>[];
      if (mounted) {
        setState(() {
          _allGroups = items;
          _loadingGroups = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingGroups = false);
    }
  }

  bool _hasChanges() {
    final a = widget.account;
    final name = _nameCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    final conc = int.tryParse(_concurrencyCtrl.text) ?? 1;
    final prio = int.tryParse(_priorityCtrl.text) ?? 0;
    final mult = double.tryParse(_rateMultiplierCtrl.text) ?? 1.0;
    final lf = int.tryParse(_loadFactorCtrl.text) ?? 0;

    if (a == null) {
      // 创建模式：任何非默认值即为有变动
      return name.isNotEmpty ||
          notes.isNotEmpty ||
          conc != 1 ||
          prio != 0 ||
          mult != 1.0 ||
          lf != 0 ||
          !_schedulable ||
          _autoPauseOnExpired ||
          _expiresAt != null ||
          _selectedGroupIds.isNotEmpty;
    }

    return name != a.name ||
        notes != (a.notes ?? '') ||
        _platform.trim().toLowerCase() != a.platform.trim().toLowerCase() ||
        _type != a.type ||
        _status != a.status ||
        conc != a.concurrency ||
        prio != a.priority ||
        mult != a.rateMultiplier ||
        lf != (a.loadFactor ?? 0) ||
        _schedulable != a.schedulable ||
        _autoPauseOnExpired != a.autoPauseOnExpired ||
        _expiresAt != a.expiresAt ||
        !_setEquals(_selectedGroupIds, a.groupIds.toSet());
  }

  bool _setEquals(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final conc = int.tryParse(_concurrencyCtrl.text) ?? 1;
    final prio = int.tryParse(_priorityCtrl.text) ?? 0;
    final mult = double.tryParse(_rateMultiplierCtrl.text) ?? 1.0;
    final lf = int.tryParse(_loadFactorCtrl.text) ?? 0;

    final payload = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'platform': _platform,
      'type': _type,
      'concurrency': conc,
      'priority': prio,
      'rate_multiplier': mult,
      'load_factor': lf,
      'schedulable': _schedulable,
      'auto_pause_on_expired': _autoPauseOnExpired,
      'group_ids': _selectedGroupIds.toList(),
    };

    // 到期时间（Unix 秒级时间戳）
    if (_expiresAt != null) {
      payload['expires_at'] = _expiresAt!.millisecondsSinceEpoch ~/ 1000;
    } else {
      payload['expires_at'] = null;
    }

    // 编辑模式额外提交状态
    if (widget.account != null) {
      payload['status'] = _status;
    }

    setState(() => _saving = true);
    try {
      final notifier = ref.read(accountsListProvider.notifier);
      if (widget.account != null) {
        await notifier.updateAccount(widget.account!.id, payload);
      } else {
        // 创建模式需要 credentials（这里给个空占位，后端校验）
        payload['credentials'] = {};
        await notifier.createAccount(payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.account != null ? '更新成功' : '创建成功')),
        );
        Navigator.pop(context);
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

  Future<void> _pickExpiresAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_expiresAt ?? now),
      );
      setState(() {
        _expiresAt = DateTime(
          date.year, date.month, date.day,
          time?.hour ?? 0, time?.minute ?? 0,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.account != null;

    return PopScope(
      canPop: !_hasChanges() || _saving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('放弃修改？'),
            content: const Text('您有未保存的修改，确定要离开吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('确定', style: TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        );
        if (proceed == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? '编辑账号' : '创建账号'),
          actions: [
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              TextButton.icon(
                icon: const Icon(Icons.check, size: 18),
                label: Text(isEdit ? '更新' : '创建'),
                onPressed: _submit,
              ),
          ],
        ),
        body: _loadingGroups
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        // ── 1. 名称 ──
                        _buildLabel('名称'),
                        TextFormField(
                          controller: _nameCtrl,
                          validator: (v) => (v == null || v.trim().isEmpty) ? '请输入账号名称' : null,
                          decoration: const InputDecoration(hintText: '请输入账号名称'),
                        ),
                        const SizedBox(height: 18),

                        // ── 2. 备注 ──
                        _buildLabel('备注'),
                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(hintText: '可选的账号备注信息'),
                        ),
                        const SizedBox(height: 18),

                        // ── 3. 平台 ──
                        _buildLabel('平台'),
                        DropdownButtonFormField<String>(
                          value: _platform,
                          decoration: const InputDecoration(
                            helperText: '创建后不可更改平台',
                            helperStyle: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          items: _platformOptions
                              .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                              .toList(),
                          onChanged: isEdit
                              ? null
                              : (v) {
                                  if (v != null) setState(() => _platform = v);
                                },
                        ),
                        const SizedBox(height: 18),

                        // ── 4. 类型 ──
                        _buildLabel('类型', icon: Icons.help_outline,
                            tooltip: '账号凭证类型，不同类型需要不同的凭证信息'),
                        DropdownButtonFormField<String>(
                          value: _typeOptions.any((e) => e.$1 == _type) ? _type : _typeOptions.first.$1,
                          items: _typeOptions
                              .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _type = v);
                          },
                        ),
                        const SizedBox(height: 18),

                        // ── 5. 状态（仅编辑模式）──
                        if (isEdit) ...[
                          _buildLabel('状态'),
                          DropdownButtonFormField<String>(
                            value: ['active', 'inactive', 'error'].contains(_status) ? _status : 'active',
                            items: const [
                              DropdownMenuItem(value: 'active', child: Text('正常')),
                              DropdownMenuItem(value: 'inactive', child: Text('停用')),
                              DropdownMenuItem(value: 'error', child: Text('错误')),
                            ],
                            onChanged: (v) => setState(() => _status = v ?? 'active'),
                          ),
                          const SizedBox(height: 18),
                        ],

                        const Divider(height: 32),

                        // ── 6. 运营参数 ──
                        Text(
                          '运营参数',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary),
                        ),
                        const SizedBox(height: 12),

                        // 并发数
                        _buildLabel('并发数', icon: Icons.help_outline,
                            tooltip: '该账号允许的最大并发请求数'),
                        TextFormField(
                          controller: _concurrencyCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) => (int.tryParse(v ?? '') == null) ? '请输入有效整数' : null,
                          decoration: const InputDecoration(hintText: '默认 1'),
                        ),
                        const SizedBox(height: 14),

                        // 优先级
                        _buildLabel('优先级', icon: Icons.help_outline,
                            tooltip: '数值越高，优先级越高。相同条件下优先调度高优先级账号'),
                        TextFormField(
                          controller: _priorityCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) => (int.tryParse(v ?? '') == null) ? '请输入有效整数' : null,
                          decoration: const InputDecoration(hintText: '默认 0'),
                        ),
                        const SizedBox(height: 14),

                        // 费率倍数
                        _buildLabel('费率倍数', icon: Icons.help_outline,
                            tooltip: '该账号的费率倍率。1.0 表示原价，0.5 表示半价'),
                        TextFormField(
                          controller: _rateMultiplierCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => (double.tryParse(v ?? '') == null) ? '请输入有效数字' : null,
                          decoration: const InputDecoration(hintText: '默认 1.0'),
                        ),
                        const SizedBox(height: 14),

                        // 负载系数
                        _buildLabel('负载系数', icon: Icons.help_outline,
                            tooltip: '影响负载均衡权重。0 为自动'),
                        TextFormField(
                          controller: _loadFactorCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '0 = 自动'),
                        ),

                        const Divider(height: 32),

                        // ── 7. 调度控制 ──
                        _buildSwitchTile(
                          title: '可调度',
                          tooltip: '关闭后该账号不会被调度引擎选中，但不影响直接访问',
                          value: _schedulable,
                          activeLabel: '启用',
                          inactiveLabel: '停用',
                          onChanged: (v) => setState(() => _schedulable = v),
                        ),
                        const Divider(height: 32),

                        // ── 8. 到期时间 ──
                        _buildLabel('到期时间'),
                        InkWell(
                          onTap: _pickExpiresAt,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              hintText: '点击选择到期时间',
                              suffixIcon: _expiresAt != null
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () => setState(() => _expiresAt = null),
                                    )
                                  : const Icon(Icons.calendar_today, size: 18),
                            ),
                            child: Text(
                              _expiresAt != null
                                  ? '${_expiresAt!.year}-${_expiresAt!.month.toString().padLeft(2, '0')}-${_expiresAt!.day.toString().padLeft(2, '0')} ${_expiresAt!.hour.toString().padLeft(2, '0')}:${_expiresAt!.minute.toString().padLeft(2, '0')}'
                                  : '不限制',
                              style: TextStyle(
                                color: _expiresAt != null ? null : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildSwitchTile(
                          title: '到期自动停用',
                          tooltip: '开启后，账号过期时自动切换为 inactive 状态',
                          value: _autoPauseOnExpired,
                          activeLabel: '启用',
                          inactiveLabel: '关闭',
                          onChanged: (v) => setState(() => _autoPauseOnExpired = v),
                        ),

                        const Divider(height: 32),

                        // ── 9. 分组关联 ──
                        _buildLabel('关联分组', icon: Icons.help_outline,
                            tooltip: '将此账号绑定到一个或多个分组，绑定后该分组的用户才能使用此账号'),
                        if (_allGroups.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('暂无可用分组', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _allGroups.map((g) {
                              final selected = _selectedGroupIds.contains(g.id);
                              return FilterChip(
                                label: Text(
                                  '${g.name} (${g.platform.toUpperCase()})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                    color: selected ? cs.primary : cs.onSurfaceVariant,
                                  ),
                                ),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    if (selected) {
                                      _selectedGroupIds.remove(g.id);
                                    } else {
                                      _selectedGroupIds.add(g.id);
                                    }
                                  });
                                },
                                selectedColor: cs.primary.withValues(alpha: 0.15),
                                checkmarkColor: cs.primary,
                                backgroundColor: cs.surfaceContainerLow,
                                side: BorderSide(
                                  color: selected
                                      ? cs.primary.withValues(alpha: 0.3)
                                      : cs.outlineVariant,
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 48),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: Text(isEdit ? '保存账号修改' : '确认创建账号'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _saving ? null : _submit,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  复用型构建方法
  // ═══════════════════════════════════════════════

  Widget _buildLabel(String text, {IconData? icon, String? tooltip}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          if (icon != null && tooltip != null) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: tooltip,
              triggerMode: TooltipTriggerMode.tap,
              child: Icon(icon, size: 14, color: Colors.grey),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? tooltip,
    required bool value,
    String? activeLabel,
    String? inactiveLabel,
    required ValueChanged<bool> onChanged,
  }) {
    final hasSuffix = activeLabel != null && inactiveLabel != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            if (tooltip != null) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: tooltip,
                triggerMode: TooltipTriggerMode.tap,
                child: const Icon(Icons.help_outline, size: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
        Row(
          children: [
            if (hasSuffix)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  value ? activeLabel : inactiveLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ],
    );
  }
}
