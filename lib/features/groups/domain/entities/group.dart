/// 基础分组实体。
///
/// 对齐 backend/internal/handler/dto/types.go 中的 Group DTO。
///
/// @author ZHANGCHAO
/// @date 2026/06/27
class Group {
  final int id;
  final String name;
  final String description;
  final String platform;
  final double rateMultiplier;
  final bool isExclusive;
  final String status;
  final String subscriptionType;
  final double? dailyLimitUSD;
  final double? weeklyLimitUSD;
  final double? monthlyLimitUSD;
  final int rpmLimit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // 网页端新增对齐字段
  final int? fallbackGroupIDOnInvalidRequest;
  final bool requireOAuthOnly;
  final bool requirePrivacySet;
  final bool claudeCodeOnly;
  final bool modelsListConfigEnabled;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.platform,
    required this.rateMultiplier,
    required this.isExclusive,
    required this.status,
    required this.subscriptionType,
    this.dailyLimitUSD,
    this.weeklyLimitUSD,
    this.monthlyLimitUSD,
    required this.rpmLimit,
    this.createdAt,
    this.updatedAt,
    this.fallbackGroupIDOnInvalidRequest,
    this.requireOAuthOnly = false,
    this.requirePrivacySet = false,
    this.claudeCodeOnly = false,
    this.modelsListConfigEnabled = false,
  });

  bool get isActive => status == 'active';

  factory Group.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return Group(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      rateMultiplier: (json['rate_multiplier'] as num?)?.toDouble() ?? 1.0,
      isExclusive: json['is_exclusive'] as bool? ?? false,
      status: json['status']?.toString() ?? 'active',
      subscriptionType: json['subscription_type']?.toString() ?? 'balance',
      dailyLimitUSD: (json['daily_limit_usd'] as num?)?.toDouble(),
      weeklyLimitUSD: (json['weekly_limit_usd'] as num?)?.toDouble(),
      monthlyLimitUSD: (json['monthly_limit_usd'] as num?)?.toDouble(),
      rpmLimit: (json['rpm_limit'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      fallbackGroupIDOnInvalidRequest:
          (json['fallback_group_id_on_invalid_request'] as num?)?.toInt(),
      requireOAuthOnly: json['require_oauth_only'] as bool? ?? false,
      requirePrivacySet: json['require_privacy_set'] as bool? ?? false,
      claudeCodeOnly: json['claude_code_only'] as bool? ?? false,
      modelsListConfigEnabled:
          (json['models_list_config'] as Map<String, dynamic>?)?['enabled'] as bool? ??
              false,
    );
  }
}

/// 管理员视角的群组扩展实体。
///
/// 对齐 backend/internal/handler/dto/types.go 中的 AdminGroup DTO。
///
/// @author ZHANGCHAO
/// @date 2026/06/27
class AdminGroup extends Group {
  final int accountCount;
  final int activeAccountCount;
  final int rateLimitedAccountCount;
  final int sortOrder;

  // 网页端新增对齐字段
  final bool modelRoutingEnabled;

  const AdminGroup({
    required super.id,
    required super.name,
    required super.description,
    required super.platform,
    required super.rateMultiplier,
    required super.isExclusive,
    required super.status,
    required super.subscriptionType,
    super.dailyLimitUSD,
    super.weeklyLimitUSD,
    super.monthlyLimitUSD,
    required super.rpmLimit,
    super.createdAt,
    super.updatedAt,
    super.fallbackGroupIDOnInvalidRequest,
    super.requireOAuthOnly,
    super.requirePrivacySet,
    super.claudeCodeOnly,
    super.modelsListConfigEnabled,
    required this.accountCount,
    required this.activeAccountCount,
    required this.rateLimitedAccountCount,
    required this.sortOrder,
    this.modelRoutingEnabled = false,
  });

  factory AdminGroup.fromJson(Map<String, dynamic> json) {
    final base = Group.fromJson(json);
    return AdminGroup(
      id: base.id,
      name: base.name,
      description: base.description,
      platform: base.platform,
      rateMultiplier: base.rateMultiplier,
      isExclusive: base.isExclusive,
      status: base.status,
      subscriptionType: base.subscriptionType,
      dailyLimitUSD: base.dailyLimitUSD,
      weeklyLimitUSD: base.weeklyLimitUSD,
      monthlyLimitUSD: base.monthlyLimitUSD,
      rpmLimit: base.rpmLimit,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      fallbackGroupIDOnInvalidRequest: base.fallbackGroupIDOnInvalidRequest,
      requireOAuthOnly: base.requireOAuthOnly,
      requirePrivacySet: base.requirePrivacySet,
      claudeCodeOnly: base.claudeCodeOnly,
      modelsListConfigEnabled: base.modelsListConfigEnabled,
      accountCount: (json['account_count'] as num?)?.toInt() ?? 0,
      activeAccountCount: (json['active_account_count'] as num?)?.toInt() ?? 0,
      rateLimitedAccountCount:
          (json['rate_limited_account_count'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      modelRoutingEnabled: json['model_routing_enabled'] as bool? ?? false,
    );
  }
}

/// 分组下用户专属倍率/RPM 配置条目。
///
/// 对齐 backend/internal/service/user_group_rate.go 中的 UserGroupRateEntry 结构。
///
/// @author ZHANGCHAO
/// @date 2026/06/27
class UserGroupRateEntry {
  final int userId;
  final String userName;
  final String userEmail;
  final String userNotes;
  final String userStatus;
  final double? rateMultiplier;
  final int? rpmOverride;

  const UserGroupRateEntry({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userNotes,
    required this.userStatus,
    this.rateMultiplier,
    this.rpmOverride,
  });

  factory UserGroupRateEntry.fromJson(Map<String, dynamic> json) {
    return UserGroupRateEntry(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      userName: json['user_name']?.toString() ?? '',
      userEmail: json['user_email']?.toString() ?? '',
      userNotes: json['user_notes']?.toString() ?? '',
      userStatus: json['user_status']?.toString() ?? '',
      rateMultiplier: (json['rate_multiplier'] as num?)?.toDouble(),
      rpmOverride: (json['rpm_override'] as num?)?.toInt(),
    );
  }
}
