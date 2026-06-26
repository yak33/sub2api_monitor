import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../domain/entities/group.dart';
import '../domain/providers/groups_provider.dart';

/// API 分组编辑/新建页面。
///
/// 界面字段、文案提示以及排版完全对齐 Web 管理端，
/// 包含防丢失提示（PopScope）与级联的只读约束属性。
///
/// @author ZHANGCHAO
/// @date 2026/06/27
class GroupEditPage extends ConsumerStatefulWidget {
  final AdminGroup? group;

  const GroupEditPage({super.key, this.group});

  @override
  ConsumerState<GroupEditPage> createState() => _GroupEditPageState();
}

class _GroupEditPageState extends ConsumerState<GroupEditPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _multiplierCtrl;
  late final TextEditingController _rpmLimitCtrl;
  late final TextEditingController _dailyLimitCtrl;
  late final TextEditingController _weeklyLimitCtrl;
  late final TextEditingController _monthlyLimitCtrl;

  String _platform = 'anthropic';
  String _status = 'active';
  String _subscriptionType = 'standard';

  bool _isExclusive = false;
  bool _claudeCodeOnly = false;
  bool _modelsListConfigEnabled = false;
  bool _requireOAuthOnly = false;
  bool _requirePrivacySet = false;
  bool _modelRoutingEnabled = false;

  int? _selectedCopyFromGroupID;
  int? _fallbackGroupIDOnInvalidRequest;

  List<AdminGroup> _allGroups = [];
  bool _loadingGroups = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.group;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _descCtrl = TextEditingController(text: g?.description ?? '');
    _multiplierCtrl = TextEditingController(text: g != null ? '${g.rateMultiplier}' : '1');
    _rpmLimitCtrl = TextEditingController(text: g != null ? '${g.rpmLimit}' : '0');
    _dailyLimitCtrl = TextEditingController(text: g?.dailyLimitUSD != null ? '${g!.dailyLimitUSD}' : '');
    _weeklyLimitCtrl = TextEditingController(text: g?.weeklyLimitUSD != null ? '${g!.weeklyLimitUSD}' : '');
    _monthlyLimitCtrl = TextEditingController(text: g?.monthlyLimitUSD != null ? '${g!.monthlyLimitUSD}' : '');

    if (g != null) {
      _platform = g.platform.toLowerCase();
      _status = g.status;
      _subscriptionType = g.subscriptionType;
      _isExclusive = g.isExclusive;
      _claudeCodeOnly = g.claudeCodeOnly;
      _modelsListConfigEnabled = g.modelsListConfigEnabled;
      _requireOAuthOnly = g.requireOAuthOnly;
      _requirePrivacySet = g.requirePrivacySet;
      _modelRoutingEnabled = g.modelRoutingEnabled;
      _fallbackGroupIDOnInvalidRequest = g.fallbackGroupIDOnInvalidRequest;
    }

    _loadGroups();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _multiplierCtrl.dispose();
    _rpmLimitCtrl.dispose();
    _dailyLimitCtrl.dispose();
    _weeklyLimitCtrl.dispose();
    _monthlyLimitCtrl.dispose();
    super.dispose();
  }

  /// 异步拉取所有可用分组列表（用于账号复制及兜底下拉）
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
      if (mounted) {
        setState(() => _loadingGroups = false);
      }
    }
  }

  /// 检查表单字段是否被改动过
  bool _hasChanges() {
    final g = widget.group;
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final mult = double.tryParse(_multiplierCtrl.text) ?? 1.0;
    final rpm = int.tryParse(_rpmLimitCtrl.text) ?? 0;
    final daily = double.tryParse(_dailyLimitCtrl.text);
    final weekly = double.tryParse(_weeklyLimitCtrl.text);
    final monthly = double.tryParse(_monthlyLimitCtrl.text);

    if (g == null) {
      return name.isNotEmpty ||
          desc.isNotEmpty ||
          _platform != 'anthropic' ||
          _status != 'active' ||
          _subscriptionType != 'standard' ||
          _isExclusive ||
          _claudeCodeOnly ||
          _modelsListConfigEnabled ||
          _requireOAuthOnly ||
          _requirePrivacySet ||
          _modelRoutingEnabled ||
          mult != 1.0 ||
          rpm != 0 ||
          daily != null ||
          weekly != null ||
          monthly != null ||
          _selectedCopyFromGroupID != null ||
          _fallbackGroupIDOnInvalidRequest != null;
    } else {
      return name != g.name ||
          desc != g.description ||
          _platform.trim().toLowerCase() != g.platform.trim().toLowerCase() ||
          _status != g.status ||
          _subscriptionType != g.subscriptionType ||
          _isExclusive != g.isExclusive ||
          _claudeCodeOnly != g.claudeCodeOnly ||
          _modelsListConfigEnabled != g.modelsListConfigEnabled ||
          _requireOAuthOnly != g.requireOAuthOnly ||
          _requirePrivacySet != g.requirePrivacySet ||
          _modelRoutingEnabled != g.modelRoutingEnabled ||
          mult != g.rateMultiplier ||
          rpm != g.rpmLimit ||
          daily != g.dailyLimitUSD ||
          weekly != g.weeklyLimitUSD ||
          monthly != g.monthlyLimitUSD ||
          _selectedCopyFromGroupID != null ||
          _fallbackGroupIDOnInvalidRequest != g.fallbackGroupIDOnInvalidRequest;
    }
  }

  /// 保存/更新分组的 Payload 组装与发送
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final mult = double.tryParse(_multiplierCtrl.text) ?? 1.0;
    final rpm = int.tryParse(_rpmLimitCtrl.text) ?? 0;

    final daily = double.tryParse(_dailyLimitCtrl.text);
    final weekly = double.tryParse(_weeklyLimitCtrl.text);
    final monthly = double.tryParse(_monthlyLimitCtrl.text);

    // 完全对齐后端 CreateGroupInput/UpdateGroupInput 结构体属性名称
    final payload = <String, dynamic>{
      'name': name,
      'description': _descCtrl.text.trim(),
      'platform': _platform,
      'rate_multiplier': mult,
      'is_exclusive': _isExclusive,
      'status': _status,
      'subscription_type': _subscriptionType,
      'rpm_limit': rpm,
      'daily_limit_usd': daily,
      'weekly_limit_usd': weekly,
      'monthly_limit_usd': monthly,
      'claude_code_only': _claudeCodeOnly,
      'models_list_config': {'enabled': _modelsListConfigEnabled},
      'require_oauth_only': _requireOAuthOnly,
      'require_privacy_set': _requirePrivacySet,
      'model_routing_enabled': _modelRoutingEnabled,
      'fallback_group_id_on_invalid_request': _fallbackGroupIDOnInvalidRequest,
    };

    if (_selectedCopyFromGroupID != null) {
      payload['copy_accounts_from_group_ids'] = [_selectedCopyFromGroupID!];
    }

    setState(() => _saving = true);
    try {
      final notifier = ref.read(groupsListProvider.notifier);
      if (widget.group != null) {
        await notifier.updateGroup(widget.group!.id, payload);
      } else {
        await notifier.createGroup(payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.group != null ? '更新成功' : '创建成功')),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.group != null;

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
        if (proceed == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? '编辑分组' : '创建分组'),
          actions: [
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
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
                        // 1. 名称
                        _buildLabel('名称'),
                        TextFormField(
                          controller: _nameCtrl,
                          validator: (v) => (v == null || v.trim().isEmpty) ? '请输入名称' : null,
                          decoration: const InputDecoration(hintText: '请输入分组名称'),
                        ),
                        const SizedBox(height: 18),

                        // 2. 描述
                        _buildLabel('描述'),
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(hintText: '关于该分组的详细说明描述'),
                        ),
                        const SizedBox(height: 18),

                        // 3. 平台
                        _buildLabel('平台'),
                        DropdownButtonFormField<String>(
                          value: _platform,
                          decoration: const InputDecoration(
                            helperText: '创建后不可更改平台',
                            helperStyle: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                            DropdownMenuItem(value: 'anthropic', child: Text('Anthropic')),
                            DropdownMenuItem(value: 'gemini', child: Text('Gemini')),
                            DropdownMenuItem(value: 'antigravity', child: Text('Antigravity')),
                            DropdownMenuItem(value: 'grok', child: Text('Grok')),
                          ],
                          onChanged: isEdit
                              ? null
                              : (v) {
                                  if (v != null) {
                                    setState(() {
                                      _platform = v;
                                      _selectedCopyFromGroupID = null;
                                      _fallbackGroupIDOnInvalidRequest = null;
                                    });
                                  }
                                },
                        ),
                        const SizedBox(height: 18),

                        // 4. 从分组复制账号
                        _buildLabel('从分组复制账号', icon: Icons.help_outline, tooltip: '选择一个或多个相同平台的分组，保存后当前分组的账号会被替换为这些分组的账号（去重）。'),
                        DropdownButtonFormField<int?>(
                          value: _selectedCopyFromGroupID,
                          hint: const Text('选择分组以复制其账号...'),
                          decoration: const InputDecoration(
                            helperText: '⚠️ 注意：这会替换当前分组的所有账号绑定',
                            helperStyle: TextStyle(fontSize: 12, color: AppTheme.warning),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('选择分组以复制其账号...')),
                            ..._allGroups
                                .where((g) =>
                                    g.id != widget.group?.id &&
                                    g.platform.trim().toLowerCase() == _platform.trim().toLowerCase())
                                .map((g) => DropdownMenuItem<int?>(
                                      value: g.id,
                                      child: Text('${g.name} (${g.platform.toUpperCase()})'),
                                    )),
                          ],
                          onChanged: (v) => setState(() => _selectedCopyFromGroupID = v),
                        ),
                        const SizedBox(height: 18),

                        // 5. 费率倍数
                        _buildLabel('费率倍数'),
                        TextFormField(
                          controller: _multiplierCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => (double.tryParse(v ?? '') == null) ? '请输入有效数字' : null,
                          decoration: const InputDecoration(hintText: '请输入费率倍率，如 1 或 1.5'),
                        ),
                        const SizedBox(height: 18),

                        // 6. 每分钟请求数 (RPM)
                        _buildLabel('每分钟请求数 (RPM)'),
                        TextFormField(
                          controller: _rpmLimitCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) => (int.tryParse(v ?? '') == null) ? '请输入有效整数' : null,
                          decoration: const InputDecoration(
                            hintText: '请输入限制数',
                            helperMaxLines: 3,
                            helperText: '每用户在本分组每分钟最大请求数，0 = 不限制；一旦设置即接管该用户的限流（覆盖用户级 rpm_limit）',
                            helperStyle: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 7. 专属分组
                        _buildSwitchTile(
                          title: '专属分组',
                          tooltip: '''
什么是专属分组？
开启后，用户在创建 API Key 时将无法看到此分组。只有管理员手动将用户分配到此分组后，用户才能使用。

💡 使用场景：公开分组费率 0.8，您可以创建一个费率 0.7 的专属分组，手动分配给 VIP 用户，让他们享受更优惠的价格。''',
                          value: _isExclusive,
                          activeLabel: '专属',
                          inactiveLabel: '公开',
                          onChanged: (v) => setState(() => _isExclusive = v),
                        ),
                        const Divider(height: 32),

                        // 8. 状态
                        _buildLabel('状态'),
                        DropdownButtonFormField<String>(
                          value: _status,
                          items: const [
                            DropdownMenuItem(value: 'active', child: Text('正常')),
                            DropdownMenuItem(value: 'inactive', child: Text('停用')),
                          ],
                          onChanged: (v) => setState(() => _status = v ?? 'active'),
                        ),
                        const SizedBox(height: 18),

                        // 9. 计费类型
                        _buildLabel('计费类型'),
                        DropdownButtonFormField<String>(
                          value: _subscriptionType,
                          decoration: const InputDecoration(
                            helperText: '分组创建后无法修改计费类型。',
                            helperStyle: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'standard', child: Text('标准（余额）')),
                            DropdownMenuItem(value: 'subscription', child: Text('订阅')),
                          ],
                          onChanged: isEdit ? null : (v) => setState(() => _subscriptionType = v ?? 'standard'),
                        ),
                        const Divider(height: 32),

                        // 10. 自定义 /v1/models 模型列表
                        _buildSwitchTile(
                          title: '自定义 /v1/models 模型列表',
                          value: _modelsListConfigEnabled,
                          helperText: '仅影响 /v1/models 展示结果，不影响白名单模型调用和账号调度。',
                          onChanged: (v) => setState(() => _modelsListConfigEnabled = v),
                        ),
                        const Divider(height: 32),

                        // 11. Claude Code 客户端限制
                        _buildSwitchTile(
                          title: 'Claude Code 客户端限制',
                          tooltip: '开启后可以针对特定的编辑器客户端环境限制 Claude Code 使用权',
                          value: _claudeCodeOnly,
                          activeLabel: '限制特定客户端',
                          inactiveLabel: '允许所有客户端',
                          onChanged: (v) => setState(() => _claudeCodeOnly = v),
                        ),
                        const Divider(height: 32),

                        // 12. 账号过滤控制 (仅 OpenAI / Antigravity 平台)
                        if (_platform == 'openai' || _platform == 'antigravity') ...[
                          Text(
                            '账号过滤控制',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary),
                          ),
                          const SizedBox(height: 10),
                          _buildSwitchTile(
                            title: '仅允许 OAuth 账号',
                            value: _requireOAuthOnly,
                            activeLabel: '启用',
                            inactiveLabel: '未启用',
                            onChanged: (v) => setState(() => _requireOAuthOnly = v),
                          ),
                          const SizedBox(height: 8),
                          _buildSwitchTile(
                            title: '仅允许隐私保护已设置的账号',
                            value: _requirePrivacySet,
                            activeLabel: '启用',
                            inactiveLabel: '未启用',
                            onChanged: (v) => setState(() => _requirePrivacySet = v),
                          ),
                          const Divider(height: 32),
                        ],

                        // 13. 无效请求兜底分组
                        _buildLabel('无效请求兜底分组'),
                        DropdownButtonFormField<int?>(
                          value: _fallbackGroupIDOnInvalidRequest,
                          decoration: const InputDecoration(
                            helperMaxLines: 2,
                            helperText: '仅当上游明确返回 prompt too long 时才会触发，留空表示不兜底',
                            helperStyle: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('不兜底')),
                            ..._allGroups
                                .where((g) =>
                                    g.id != widget.group?.id &&
                                    g.platform.trim().toLowerCase() == _platform.trim().toLowerCase())
                                .map((g) => DropdownMenuItem<int?>(
                                      value: g.id,
                                      child: Text('${g.name} (${g.platform.toUpperCase()})'),
                                    )),
                          ],
                          onChanged: (v) => setState(() => _fallbackGroupIDOnInvalidRequest = v),
                        ),
                        const Divider(height: 32),

                        // 14. 模型路由配置 (仅 Anthropic 平台)
                        if (_platform == 'anthropic') ...[
                          _buildSwitchTile(
                            title: '模型路由配置',
                            tooltip: '控制是否启用定制化的模型级转发调度规则',
                            value: _modelRoutingEnabled,
                            activeLabel: '已启用',
                            inactiveLabel: '已禁用',
                            helperText: '启用后，配置的路由规则才会生效',
                            onChanged: (v) => setState(() => _modelRoutingEnabled = v),
                          ),
                          const Divider(height: 32),
                        ],

                        // 15. 周期额度限制
                        Text(
                          '周期额度限制 (USD)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _dailyLimitCtrl,
                          decoration: const InputDecoration(labelText: '日额度限制 (选填)', prefixText: '\$ '),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _weeklyLimitCtrl,
                          decoration: const InputDecoration(labelText: '周额度限制 (选填)', prefixText: '\$ '),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _monthlyLimitCtrl,
                          decoration: const InputDecoration(labelText: '月额度限制 (选填)', prefixText: '\$ '),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),

                        const SizedBox(height: 48),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: Text(isEdit ? '保存分组修改' : '确认创建分组'),
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

  /// 统一的带 Tooltip 说明的表单标签
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

  /// 封装对齐 Web 端样式的 SwitchTile (包含随动标签与可选副说明文字)
  Widget _buildSwitchTile({
    required String title,
    String? tooltip,
    required bool value,
    String? activeLabel,
    String? inactiveLabel,
    String? helperText,
    required ValueChanged<bool> onChanged,
  }) {
    final hasSuffix = activeLabel != null && inactiveLabel != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (tooltip != null) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: tooltip,
                    triggerMode: TooltipTriggerMode.tap,
                    child: const Icon(Icons.help_outline, size: 14, color: Colors.grey),
                  ),
                ]
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
                Switch(
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ],
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              helperText,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
