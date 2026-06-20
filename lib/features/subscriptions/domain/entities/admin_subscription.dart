/// 管理员视角的订阅实体。
///
/// 对齐 sub2api 后端 `AdminUserSubscription` DTO（内嵌 [UserSubscription]），
/// 含管理员专属字段 [assignedBy] / [assignedAt] / [notes]。
/// 全字段设防缺省值，兼容后端字段增删。
class AdminSubscription {
  // ── UserSubscription 字段 ──
  final int id;
  final int userId;
  final int groupId;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final String status;
  final DateTime? dailyWindowStart;
  final DateTime? weeklyWindowStart;
  final DateTime? monthlyWindowStart;
  final double dailyUsageUsd;
  final double weeklyUsageUsd;
  final double monthlyUsageUsd;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ── AdminUserSubscription 额外字段 ──
  final int? assignedBy;
  final DateTime? assignedAt;
  final String notes;

  // ── 嵌套关联 ──
  final SubUser? user;
  final SubGroup? group;
  final SubUser? assignedByUser;

  const AdminSubscription({
    required this.id,
    required this.userId,
    required this.groupId,
    this.startsAt,
    this.expiresAt,
    this.status = 'active',
    this.dailyWindowStart,
    this.weeklyWindowStart,
    this.monthlyWindowStart,
    this.dailyUsageUsd = 0,
    this.weeklyUsageUsd = 0,
    this.monthlyUsageUsd = 0,
    this.createdAt,
    this.updatedAt,
    this.assignedBy,
    this.assignedAt,
    this.notes = '',
    this.user,
    this.group,
    this.assignedByUser,
  });

  // ── 便捷属性 ──
  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired';
  bool get hasExpiry => expiresAt != null;

  factory AdminSubscription.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic v) =>
        v == null || v.toString().isEmpty ? null : DateTime.tryParse(v.toString());

    return AdminSubscription(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      groupId: (json['group_id'] as num?)?.toInt() ?? 0,
      startsAt: _dt(json['starts_at']),
      expiresAt: _dt(json['expires_at']),
      status: json['status']?.toString() ?? 'active',
      dailyWindowStart: _dt(json['daily_window_start']),
      weeklyWindowStart: _dt(json['weekly_window_start']),
      monthlyWindowStart: _dt(json['monthly_window_start']),
      dailyUsageUsd: (json['daily_usage_usd'] as num?)?.toDouble() ?? 0,
      weeklyUsageUsd: (json['weekly_usage_usd'] as num?)?.toDouble() ?? 0,
      monthlyUsageUsd: (json['monthly_usage_usd'] as num?)?.toDouble() ?? 0,
      createdAt: _dt(json['created_at']),
      updatedAt: _dt(json['updated_at']),
      assignedBy: (json['assigned_by'] as num?)?.toInt(),
      assignedAt: _dt(json['assigned_at']),
      notes: json['notes']?.toString() ?? '',
      user: _maybeUser(json['user']),
      group: _maybeGroup(json['group']),
      assignedByUser: _maybeUser(json['assigned_by_user']),
    );
  }

  static SubUser? _maybeUser(dynamic v) {
    if (v is Map<String, dynamic>) return SubUser.fromJson(v);
    return null;
  }

  static SubGroup? _maybeGroup(dynamic v) {
    if (v is Map<String, dynamic>) return SubGroup.fromJson(v);
    return null;
  }
}

/// 订阅中内嵌的简要用户信息。
class SubUser {
  final int id;
  final String email;
  final String username;
  final String role;

  const SubUser({
    required this.id,
    this.email = '',
    this.username = '',
    this.role = 'user',
  });

  factory SubUser.fromJson(Map<String, dynamic> json) => SubUser(
        id: (json['id'] as num?)?.toInt() ?? 0,
        email: json['email']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        role: json['role']?.toString() ?? 'user',
      );
}

/// 订阅中内嵌的分组信息。
class SubGroup {
  final int id;
  final String name;
  final String platform;
  final double rateMultiplier;
  final double? dailyLimitUsd;
  final double? weeklyLimitUsd;
  final double? monthlyLimitUsd;

  const SubGroup({
    required this.id,
    this.name = '',
    this.platform = '',
    this.rateMultiplier = 1.0,
    this.dailyLimitUsd,
    this.weeklyLimitUsd,
    this.monthlyLimitUsd,
  });

  factory SubGroup.fromJson(Map<String, dynamic> json) => SubGroup(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        platform: json['platform']?.toString() ?? '',
        rateMultiplier: (json['rate_multiplier'] as num?)?.toDouble() ?? 1.0,
        dailyLimitUsd: (json['daily_limit_usd'] as num?)?.toDouble(),
        weeklyLimitUsd: (json['weekly_limit_usd'] as num?)?.toDouble(),
        monthlyLimitUsd: (json['monthly_limit_usd'] as num?)?.toDouble(),
      );
}

/// 批量分配结果。
class BulkAssignResult {
  final int successCount;
  final int createdCount;
  final int reusedCount;
  final int failedCount;
  final List<AdminSubscription> subscriptions;
  final List<String> errors;

  const BulkAssignResult({
    this.successCount = 0,
    this.createdCount = 0,
    this.reusedCount = 0,
    this.failedCount = 0,
    this.subscriptions = const [],
    this.errors = const [],
  });

  factory BulkAssignResult.fromJson(Map<String, dynamic> json) {
    final subs = (json['subscriptions'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(AdminSubscription.fromJson)
            .toList() ??
        const <AdminSubscription>[];
    final errs = (json['errors'] as List?)
            ?.whereType<String>()
            .toList() ??
        const <String>[];
    return BulkAssignResult(
      successCount: (json['success_count'] as num?)?.toInt() ?? 0,
      createdCount: (json['created_count'] as num?)?.toInt() ?? 0,
      reusedCount: (json['reused_count'] as num?)?.toInt() ?? 0,
      failedCount: (json['failed_count'] as num?)?.toInt() ?? 0,
      subscriptions: subs,
      errors: errs,
    );
  }
}
