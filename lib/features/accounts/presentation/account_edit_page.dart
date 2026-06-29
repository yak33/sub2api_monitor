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

  // ── 凭证字段 controllers ──
  // 后端 schema: credentials 结构取决于 type 字段，不同 type 需要不同凭证
  // 用 Map 统一管理所有可能的字段，切换 type 时只切换显示，不重建 controller
  final Map<String, TextEditingController> _credControllers = {};

  /// 凭证字段初始文本快照（initState 末尾拍照）。
  /// _hasChanges 对比"当前文本 vs 快照"来判断用户是否改动凭证，
  /// 彻底绕开"回填值 vs 后端原值"对比中的 trim/类型转换等边缘情况误报。
  late final Map<String, String> _initCredTexts;

  String _platform = 'anthropic';
  String _type = 'oauth';
  String _status = 'active';
  bool _schedulable = true;
  // 后端 schema 默认值：auto_pause_on_expired=true（过期自动暂停调度）
  bool _autoPauseOnExpired = true;
  // 后端 schema：load_factor 为 Optional().Nillable()，null 表示由调度器自动分配权重
  bool _loadFactorAuto = true;
  DateTime? _expiresAt;

  // ── 分组关联 ──
  List<AdminGroup> _allGroups = [];
  Set<int> _selectedGroupIds = {};
  bool _loadingGroups = true;

  bool _saving = false;

  // ── 账号类型选项（对齐后端 binding:"oneof=oauth setup-token apikey upstream bedrock service_account"）──
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

  /// 各 type 的凭证字段配置。
  /// 格式：(字段名, 显示名, 是否必填, 是否多行)
  /// 对齐后端 schema 注释 + account_base_url_test.go 实测逻辑。
  /// base_url 对 apikey/upstream 类型可选，留空使用平台默认地址。
  static const _credFieldConfig = <String, List<(String, String, bool, bool)>>{
    'apikey': [
      ('api_key', 'API Key', true, false),
      ('base_url', 'Base URL (可选)', false, false),
    ],
    'oauth': [
      ('access_token', 'Access Token', true, true),
      ('refresh_token', 'Refresh Token', false, true),
      ('expires_at', 'Token 过期时间 (ISO 8601)', false, false),
    ],
    'setup-token': [
      ('setup_token', 'Setup Token', true, true),
    ],
    'upstream': [
      ('base_url', 'Base URL', true, false),
      ('api_key', 'API Key', true, false),
    ],
    'bedrock': [
      ('access_key_id', 'Access Key ID', true, false),
      ('secret_access_key', 'Secret Access Key', true, true),
      ('region', 'Region (如 us-east-1)', true, false),
    ],
    'service_account': [
      ('project_id', 'Project ID', true, false),
      ('private_key', 'Private Key (PEM)', true, true),
      ('client_email', 'Client Email', true, false),
    ],
  };

  /// 为 controller 添加"内容变更 → setState"监听。
  /// 仅在 hasChanges 结果发生变化时才 rebuild，避免每次击键都全量重建。
  bool _lastHasChanges = false;

  void _addDirtyListener(TextEditingController ctrl) {
    ctrl.addListener(() {
      final now = _hasChanges();
      if (now != _lastHasChanges) {
        _lastHasChanges = now;
        setState(() {});
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _notesCtrl = TextEditingController(text: a?.notes ?? '');
    // 后端 schema 默认值：concurrency=3, priority=50, rate_multiplier=1.0
    _concurrencyCtrl = TextEditingController(text: '${a?.concurrency ?? 3}');
    _priorityCtrl = TextEditingController(text: '${a?.priority ?? 50}');
    _rateMultiplierCtrl = TextEditingController(text: '${a?.rateMultiplier ?? 1.0}');
    // load_factor 手动模式下的默认显示值（实际是否提交取决于 _loadFactorAuto）
    _loadFactorCtrl = TextEditingController(text: '${a?.loadFactor ?? 1}');

    // 初始化所有凭证字段 controller
    for (final key in _allCredentialKeys) {
      _credControllers[key] = TextEditingController();
    }

    if (a != null) {
      _platform = a.platform.toLowerCase();
      _type = a.type;
      _status = a.status;
      _schedulable = a.schedulable;
      _autoPauseOnExpired = a.autoPauseOnExpired;
      // null = 自动（由调度器分配权重），非 null = 手动指定权重
      _loadFactorAuto = a.loadFactor == null;
      _expiresAt = a.expiresAt;
      _selectedGroupIds = a.groupIds.toSet();

      // 回填凭证：后端 RedactCredentials 已剥离敏感字段（api_key/access_token 等），
      // 但保留非敏感字段（如 base_url、region、project_id、client_email、expires_at）。
      // 这些字段可直接回填到输入框，用户编辑时看到当前值，留空或不改即维持原值。
      for (final entry in a.credentials.entries) {
        final ctrl = _credControllers[entry.key];
        if (ctrl != null && entry.value != null) {
          ctrl.text = entry.value.toString();
        }
      }
    }

    // 拍照凭证初始文本：必须在所有回填完成后，用于精确判断用户是否改动。
    // 后续 _hasChanges 对比"当前文本 vs 此快照"，不依赖后端原值，避免 trim 等边缘误报。
    _initCredTexts = {
      for (final key in _allCredentialKeys)
        key: _credControllers[key]?.text ?? '',
    };

    // 为所有 TextEditingController 添加监听器，
    // 输入内容变化时触发 setState，使 PopScope.canPop 及时更新。
    _addDirtyListener(_nameCtrl);
    _addDirtyListener(_notesCtrl);
    _addDirtyListener(_concurrencyCtrl);
    _addDirtyListener(_priorityCtrl);
    _addDirtyListener(_rateMultiplierCtrl);
    _addDirtyListener(_loadFactorCtrl);
    for (final c in _credControllers.values) {
      _addDirtyListener(c);
    }

    _loadGroups();
  }

  /// 所有凭证字段的 key 集合（去重），用于初始化 controller
  static final _allCredentialKeys = _credFieldConfig.values
      .expand((fields) => fields)
      .map((f) => f.$1)
      .toSet();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _concurrencyCtrl.dispose();
    _priorityCtrl.dispose();
    _rateMultiplierCtrl.dispose();
    _loadFactorCtrl.dispose();
    for (final c in _credControllers.values) {
      c.dispose();
    }
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
    // 默认值与后端 schema 对齐：concurrency=3, priority=50, rate_multiplier=1.0
    final conc = int.tryParse(_concurrencyCtrl.text) ?? 3;
    final prio = int.tryParse(_priorityCtrl.text) ?? 50;
    final mult = double.tryParse(_rateMultiplierCtrl.text) ?? 1.0;
    final lf = int.tryParse(_loadFactorCtrl.text) ?? 1;

    if (a == null) {
      // 创建模式：任何非默认值即为有变动
      // 后端默认：concurrency=3, priority=50, rate_multiplier=1.0,
      //           load_factor=null(自动), schedulable=true, auto_pause_on_expired=true
      return name.isNotEmpty ||
          notes.isNotEmpty ||
          _hasCredChanges() || // 凭证字段有填写即算变动
          conc != 3 ||
          prio != 50 ||
          mult != 1.0 ||
          !_loadFactorAuto || // 切到手动模式即算变动
          !_schedulable ||
          !_autoPauseOnExpired || // 默认 true，关闭算变动
          _expiresAt != null ||
          _selectedGroupIds.isNotEmpty;
    }

    // 编辑模式：load_factor 自动状态或具体值变化都算变动
    // - 自动状态变化：_loadFactorAuto != (原 loadFactor == null)
    // - 手动模式下值变化：!_loadFactorAuto && lf != 原值
    final lfChanged = _loadFactorAuto != (a.loadFactor == null) ||
        (!_loadFactorAuto && lf != (a.loadFactor ?? 0));

    return name != a.name ||
        notes != (a.notes ?? '') ||
        _platform.trim().toLowerCase() != a.platform.trim().toLowerCase() ||
        _type != a.type ||
        _status != a.status ||
        conc != a.concurrency ||
        prio != a.priority ||
        mult != a.rateMultiplier ||
        lfChanged ||
        _schedulable != a.schedulable ||
        _autoPauseOnExpired != a.autoPauseOnExpired ||
        _expiresAt != a.expiresAt ||
        _hasCredChanges() || // 对比当前文本 vs 初始快照，精确判断凭证是否改动
        !_setEquals(_selectedGroupIds, a.groupIds.toSet());
  }

  /// 判断当前 type 的凭证字段是否有任何改动（对比 initState 拍的快照）。
  /// 不依赖后端原值，避免 trim/类型转换等边缘情况导致的误报。
  bool _hasCredChanges() {
    final fields = _credFieldConfig[_type] ?? const [];
    for (final (key, _, _, _) in fields) {
      final current = _credControllers[key]?.text ?? '';
      if (current != (_initCredTexts[key] ?? '')) {
        return true;
      }
    }
    return false;
  }

  bool _setEquals(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  /// 收集当前 type 的凭证字段，返回 credentials map。
  /// - 创建模式：收集所有非空字段
  /// - 编辑模式：仅收集与原值不同的字段（含新增的敏感字段），
  ///   未改动的非敏感字段（如 base_url 与原值相同）会被跳过，避免无谓重提交。
  Map<String, dynamic> _collectCredentials() {
    final fields = _credFieldConfig[_type] ?? const [];
    final creds = <String, dynamic>{};
    final a = widget.account;
    final origCreds = a?.credentials ?? const {};
    for (final (key, _, _, _) in fields) {
      final value = _credControllers[key]?.text.trim() ?? '';
      if (value.isEmpty) continue;
      // 编辑模式：跳过与原值相同的字段（base_url 没改就不重交）
      if (a != null && value == (origCreds[key]?.toString() ?? '')) {
        continue;
      }
      creds[key] = value;
    }
    return creds;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final conc = int.tryParse(_concurrencyCtrl.text) ?? 3;
    final prio = int.tryParse(_priorityCtrl.text) ?? 50;
    final mult = double.tryParse(_rateMultiplierCtrl.text) ?? 1.0;
    final lf = int.tryParse(_loadFactorCtrl.text) ?? 1;
    final isEdit = widget.account != null;

    // 凭证收集：
    // - 创建模式：credentials 必填（后端 binding:"required"），且至少要有一个字段
    // - 编辑模式：credentials 可选，留空表示不修改现有凭证
    final credentials = _collectCredentials();
    if (!isEdit && credentials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请至少填写一项凭证信息'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final payload = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'platform': _platform,
      'type': _type,
      'concurrency': conc,
      'priority': prio,
      'rate_multiplier': mult,
      // load_factor: null = 自动（后端 Optional().Nillable()），数字 = 具体权重
      'load_factor': _loadFactorAuto ? null : lf,
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

    // 凭证：创建模式必填，编辑模式仅在用户填写时提交（避免覆盖为空）
    if (isEdit) {
      if (credentials.isNotEmpty) {
        payload['credentials'] = credentials;
      }
      payload['status'] = _status;
    } else {
      payload['credentials'] = credentials;
    }

    setState(() => _saving = true);
    try {
      final notifier = ref.read(accountsListProvider.notifier);
      if (isEdit) {
        await notifier.updateAccount(widget.account!.id, payload);
      } else {
        await notifier.createAccount(payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? '更新成功' : '创建成功')),
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
    final hasChanges = _hasChanges();
    // 同步 dirty 追踪标记，避免 Dropdown/Switch 触发的 rebuild
    // 导致 text listener 产生多余的 setState。
    _lastHasChanges = hasChanges;

    return PopScope(
      canPop: !hasChanges || _saving,
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

                        // ── 4.1 凭证信息（根据类型动态显示字段）──
                        _buildCredentialsSection(isEdit),
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
                            tooltip: '该账号允许的最大并发请求数（默认 3）'),
                        TextFormField(
                          controller: _concurrencyCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) => (int.tryParse(v ?? '') == null) ? '请输入有效整数' : null,
                          decoration: const InputDecoration(hintText: '默认 3'),
                        ),
                        const SizedBox(height: 14),

                        // 优先级（后端语义：数值越小优先级越高，默认 50）
                        _buildLabel('优先级', icon: Icons.help_outline,
                            tooltip: '数值越小优先级越高。相同条件下优先调度低数值账号（默认 50）'),
                        TextFormField(
                          controller: _priorityCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) => (int.tryParse(v ?? '') == null) ? '请输入有效整数' : null,
                          decoration: const InputDecoration(hintText: '默认 50'),
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

                        // 负载系数（null = 自动，数字 = 具体权重）
                        _buildLabel('负载系数', icon: Icons.help_outline,
                            tooltip: '影响负载均衡权重。开启"自动"由调度器决定，关闭后可手动指定权重值'),
                        _buildSwitchTile(
                          title: '自动负载系数',
                          tooltip: '开启后由调度器自动分配权重；关闭后使用下方指定的固定权重',
                          value: _loadFactorAuto,
                          activeLabel: '自动',
                          inactiveLabel: '手动',
                          onChanged: (v) => setState(() => _loadFactorAuto = v),
                        ),
                        if (!_loadFactorAuto) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _loadFactorCtrl,
                            keyboardType: TextInputType.number,
                            validator: (v) => (int.tryParse(v ?? '') == null) ? '请输入有效整数' : null,
                            decoration: const InputDecoration(hintText: '负载权重（正整数）'),
                          ),
                        ],

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

  /// 构建凭证信息区域。根据当前 [_type] 动态渲染对应的凭证字段。
  ///
  /// 后端 schema: credentials 结构取决于 type 字段，不同类型需要不同凭证。
  /// - 创建模式：必填字段强制校验
  /// - 编辑模式：所有字段可选（留空表示不修改现有凭证，后端凭证已 redact）
  Widget _buildCredentialsSection(bool isEdit) {
    final cs = Theme.of(context).colorScheme;
    final fields = _credFieldConfig[_type] ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '凭证信息',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary),
        ),
        const SizedBox(height: 4),
        Text(
          isEdit
              ? '非敏感字段（如 Base URL）已回显当前值；敏感字段（API Key/Token 等）不回显，留空表示不修改'
              : '创建账号时凭证必填，请按类型填写',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        for (final (key, label, required, multiline) in fields) ...[
          _buildLabel(
            required ? '$label *' : label,
            icon: Icons.help_outline,
            tooltip: _credFieldHints[key] ?? '请输入$label',
          ),
          // 注意：Flutter 框架限制 obscureText 与 maxLines>1 不可同时使用
          // 多行字段（token/private_key）默认明文显示，单行敏感字段才脱敏
          // spread for-body 内不能用 final 声明，全部内联到参数中
          TextFormField(
            controller: _credControllers[key],
            maxLines: (_shouldObscure(key) && !multiline) ? 1 : (multiline ? 4 : 1),
            obscureText: _shouldObscure(key) && !multiline && !(_credVisible[key] ?? false),
            keyboardType: multiline
                ? TextInputType.multiline
                : (key == 'client_email' ? TextInputType.emailAddress : TextInputType.text),
            validator: (v) {
              // 创建模式下必填字段校验
              if (!isEdit && required && (v == null || v.trim().isEmpty)) {
                return '请输入$label';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: '请输入$label',
              suffixIcon: (_shouldObscure(key) && !multiline)
                  ? IconButton(
                      icon: Icon(
                        _credVisible[key] == true ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                      ),
                      onPressed: () => setState(() {
                        _credVisible[key] = !(_credVisible[key] ?? false);
                      }),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// 敏感字段需要脱敏显示（点击眼睛图标可切换明文）
  static const _sensitiveKeys = {
    'api_key', 'access_token', 'refresh_token', 'setup_token',
    'secret_access_key', 'private_key',
  };

  bool _shouldObscure(String key) => _sensitiveKeys.contains(key);

  /// 各凭证字段的帮助提示
  static const _credFieldHints = {
    'api_key': '平台的 API Key，如 sk-ant-xxx',
    'base_url': '自定义 API 端点。留空使用平台默认地址（如 https://api.anthropic.com）',
    'access_token': 'OAuth 授权后的访问令牌',
    'refresh_token': '用于刷新 access_token 的令牌（可选）',
    'expires_at': 'Token 过期时间，ISO 8601 格式如 2026-12-31T23:59:59Z',
    'setup_token': '平台提供的 Setup Token',
    'access_key_id': 'AWS Access Key ID',
    'secret_access_key': 'AWS Secret Access Key',
    'region': 'AWS 区域，如 us-east-1',
    'project_id': 'GCP 项目 ID',
    'private_key': 'GCP 服务账号的 Private Key（PEM 格式，含 BEGIN/END 标记）',
    'client_email': '服务账号邮箱，如 xxx@project.iam.gserviceaccount.com',
  };

  /// 凭证字段的明文/脱敏显示状态（key -> 是否明文）
  final Map<String, bool> _credVisible = {};

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
