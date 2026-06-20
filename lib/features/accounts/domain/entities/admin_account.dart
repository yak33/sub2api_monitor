/// 管理员视角的 AI 账号实体。
///
/// 对齐 sub2api 后端 `dto.Account` + `AccountWithConcurrency`，
/// 核心展示字段完整映射，配额/窗口/指纹等高级字段按需在详情页展开。
class AdminAccount {
  final int id;
  final String name;
  final String platform;
  final String type;
  final String status;
  final String? errorMessage;
  final int concurrency;
  final int priority;
  final double rateMultiplier;
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

  const AdminAccount({
    required this.id,
    required this.name,
    required this.platform,
    required this.type,
    required this.status,
    this.errorMessage,
    this.concurrency = 1,
    this.priority = 0,
    this.rateMultiplier = 1.0,
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

  factory AdminAccount.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic v) =>
        v == null || v.toString().isEmpty ? null : DateTime.tryParse(v.toString());
    double? _d(dynamic v) => (v as num?)?.toDouble();
    int? _i(dynamic v) => (v as num?)?.toInt();

    // 嵌套 proxy
    final proxy = json['proxy'] as Map<String, dynamic>?;

    return AdminAccount(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? 'inactive',
      errorMessage: json['error_message']?.toString(),
      concurrency: (json['concurrency'] as num?)?.toInt() ?? 1,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      rateMultiplier: (json['rate_multiplier'] as num?)?.toDouble() ?? 1.0,
      baseRpm: _i(json['base_rpm']),
      schedulable: json['schedulable'] as bool? ?? true,
      lastUsedAt: _dt(json['last_used_at']),
      expiresAt: _i(json['expires_at']) != null
          ? DateTime.fromMillisecondsSinceEpoch(_i(json['expires_at'])! * 1000)
          : null,
      autoPauseOnExpired: json['auto_pause_on_expired'] as bool? ?? false,
      createdAt: _dt(json['created_at']),
      updatedAt: _dt(json['updated_at']),
      currentConcurrency: (json['current_concurrency'] as num?)?.toInt() ?? 0,
      currentWindowCost: _d(json['current_window_cost']),
      activeSessions: _i(json['active_sessions']),
      currentRpm: _i(json['current_rpm']),
      quotaLimit: _d(json['quota_limit']),
      quotaUsed: _d(json['quota_used']),
      quotaDailyLimit: _d(json['quota_daily_limit']),
      quotaDailyUsed: _d(json['quota_daily_used']),
      quotaWeeklyLimit: _d(json['quota_weekly_limit']),
      quotaWeeklyUsed: _d(json['quota_weekly_used']),
      proxyId: _i(json['proxy_id']),
      proxyName: proxy?['name']?.toString(),
      rateLimitedAt: _dt(json['rate_limited_at']),
      rateLimitResetAt: _dt(json['rate_limit_reset_at']),
      overloadUntil: _dt(json['overload_until']),
    );
  }
}
