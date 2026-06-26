/// 管理员视角的 AI 账号实体。
///
/// 对齐 sub2api 后端 `dto.Account` + `AccountWithConcurrency`，
/// 核心展示字段完整映射，配额/窗口/指纹等高级字段按需在详情页展开。
///
/// @author ZHANGCHAO
/// @date 2026/06/27
class AdminAccount {
  final int id;
  final String name;
  final String? notes;
  final String platform;
  final String type;
  final String status;
  final String? errorMessage;
  final int concurrency;
  final int priority;
  final double rateMultiplier;
  final int? loadFactor;
  final int? baseRpm;
  final bool schedulable;
  final DateTime? lastUsedAt;
  final DateTime? expiresAt;
  final bool autoPauseOnExpired;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ── AccountWithConcurrency 额外字段 ──
  final int currentConcurrency;
  final double? currentWindowCost;
  final int? activeSessions;
  final int? currentRpm;

  // ── 配额 ──
  final double? quotaLimit;
  final double? quotaUsed;
  final double? quotaDailyLimit;
  final double? quotaDailyUsed;
  final double? quotaWeeklyLimit;
  final double? quotaWeeklyUsed;

  // ── 代理 ──
  final int? proxyId;
  final String? proxyName;

  // ── 速率限制状态 ──
  final DateTime? rateLimitedAt;
  final DateTime? rateLimitResetAt;
  final DateTime? overloadUntil;

  // ── 关联分组 ──
  final List<AccountGroup> groups;

  const AdminAccount({
    required this.id,
    required this.name,
    this.notes,
    required this.platform,
    required this.type,
    required this.status,
    this.errorMessage,
    this.concurrency = 1,
    this.priority = 0,
    this.rateMultiplier = 1.0,
    this.loadFactor,
    this.baseRpm,
    this.schedulable = true,
    this.lastUsedAt,
    this.expiresAt,
    this.autoPauseOnExpired = false,
    this.createdAt,
    this.updatedAt,
    this.currentConcurrency = 0,
    this.currentWindowCost,
    this.activeSessions,
    this.currentRpm,
    this.quotaLimit,
    this.quotaUsed,
    this.quotaDailyLimit,
    this.quotaDailyUsed,
    this.quotaWeeklyLimit,
    this.quotaWeeklyUsed,
    this.proxyId,
    this.proxyName,
    this.rateLimitedAt,
    this.rateLimitResetAt,
    this.overloadUntil,
    this.groups = const [],
  });

  // ── 便捷属性 ──
  bool get isActive => status == 'active';
  bool get isError => status == 'error';
  bool get isInactive => status == 'inactive';
  bool get isRateLimited => status == 'ratelimit';
  bool get isOverloaded => status == 'overload';
  bool get isExpired =>
      expiresAt != null &&
      DateTime.now().millisecondsSinceEpoch >
          (expiresAt!.millisecondsSinceEpoch);

  /// 到期时间的 Unix 秒级时间戳（后端接收格式）
  int? get expiresAtEpoch =>
      expiresAt != null ? expiresAt!.millisecondsSinceEpoch ~/ 1000 : null;

  /// 关联分组的 ID 列表
  List<int> get groupIds => groups.map((g) => g.id).toList();

  factory AdminAccount.fromJson(Map<String, dynamic> json) {
    DateTime? dt(dynamic v) =>
        v == null || v.toString().isEmpty ? null : DateTime.tryParse(v.toString());
    double? d(dynamic v) => (v as num?)?.toDouble();
    int? i(dynamic v) => (v as num?)?.toInt();

    // 嵌套 proxy
    final proxy = json['proxy'] as Map<String, dynamic>?;

    // 嵌套 groups
    final rawGroups = json['groups'] as List?;
    final groups = rawGroups
            ?.whereType<Map<String, dynamic>>()
            .map(AccountGroup.fromJson)
            .toList() ??
        const <AccountGroup>[];

    return AdminAccount(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      notes: json['notes']?.toString(),
      platform: json['platform']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? 'inactive',
      errorMessage: json['error_message']?.toString(),
      concurrency: (json['concurrency'] as num?)?.toInt() ?? 1,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      rateMultiplier: (json['rate_multiplier'] as num?)?.toDouble() ?? 1.0,
      loadFactor: i(json['load_factor']),
      baseRpm: i(json['base_rpm']),
      schedulable: json['schedulable'] as bool? ?? true,
      lastUsedAt: dt(json['last_used_at']),
      expiresAt: i(json['expires_at']) != null
          ? DateTime.fromMillisecondsSinceEpoch(i(json['expires_at'])! * 1000)
          : null,
      autoPauseOnExpired: json['auto_pause_on_expired'] as bool? ?? false,
      createdAt: dt(json['created_at']),
      updatedAt: dt(json['updated_at']),
      currentConcurrency: (json['current_concurrency'] as num?)?.toInt() ?? 0,
      currentWindowCost: d(json['current_window_cost']),
      activeSessions: i(json['active_sessions']),
      currentRpm: i(json['current_rpm']),
      quotaLimit: d(json['quota_limit']),
      quotaUsed: d(json['quota_used']),
      quotaDailyLimit: d(json['quota_daily_limit']),
      quotaDailyUsed: d(json['quota_daily_used']),
      quotaWeeklyLimit: d(json['quota_weekly_limit']),
      quotaWeeklyUsed: d(json['quota_weekly_used']),
      proxyId: i(json['proxy_id']),
      proxyName: proxy?['name']?.toString(),
      rateLimitedAt: dt(json['rate_limited_at']),
      rateLimitResetAt: dt(json['rate_limit_reset_at']),
      overloadUntil: dt(json['overload_until']),
      groups: groups,
    );
  }
}

/// 账号关联的分组摘要信息。
///
/// 对齐后端 `groups` 嵌套返回结构。
class AccountGroup {
  final int id;
  final String name;
  final String platform;

  const AccountGroup({
    required this.id,
    required this.name,
    required this.platform,
  });

  factory AccountGroup.fromJson(Map<String, dynamic> json) => AccountGroup(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        platform: json['platform']?.toString() ?? '',
      );
}
