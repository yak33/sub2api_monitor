/// 仪表盘聚合数据。
///
/// 支持两种模式：
/// - **用户级**（个人监控）：由 /api/v1/usage/dashboard/* 端点拼装
/// - **管理员级**（对齐 sub2api Web DashboardView）：由 /api/v1/admin/dashboard/* 端点拼装
///
/// 通过 [isAdmin] 标志区分，UI 层据此选择布局。
/// 字段名对多版本后端做兼容兜底，未知字段缺省为 0，保证解析不抛异常。
class DashboardData {
  final bool isAdmin;

  // ── 用户级字段（个人监控）──
  final double totalBalance;
  final double todayUsage;
  final double weekUsage;
  final double monthUsage;

  // ── 管理员级字段（对齐 sub2api Web DashboardView）──
  // 用户统计
  final int totalUsers;
  final int todayNewUsers;
  final int activeUsers;
  // API Key 统计
  final int totalApiKeys;
  final int activeApiKeys;
  // 账号统计
  final int totalAccounts;
  final int normalAccounts;
  final int errorAccounts;
  final int ratelimitAccounts;
  final int overloadAccounts;
  // 累计 Token 使用统计
  final int totalRequests;
  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalCacheCreationTokens;
  final int totalCacheReadTokens;
  final int totalTokens;
  final double totalCost;
  final double totalActualCost;
  // 今日 Token 使用统计
  final int todayRequests;
  final int todayInputTokens;
  final int todayOutputTokens;
  final int todayTokens;
  final double todayCost;
  final double todayActualCost;
  // 系统运行 & 性能
  final double averageDurationMs;
  final int uptime;
  final int rpm;
  final int tpm;

  // ── 共用字段 ──
  final List<ModelUsage> topModels;
  final List<DailyUsage> dailyUsage;

  // ── 管理员专属：用户消费榜 ──
  final List<UserRankingItem> userRanking;

  const DashboardData({
    this.isAdmin = false,
    this.totalBalance = 0,
    this.todayUsage = 0,
    this.weekUsage = 0,
    this.monthUsage = 0,
    this.totalUsers = 0,
    this.todayNewUsers = 0,
    this.activeUsers = 0,
    this.totalApiKeys = 0,
    this.activeApiKeys = 0,
    this.totalAccounts = 0,
    this.normalAccounts = 0,
    this.errorAccounts = 0,
    this.ratelimitAccounts = 0,
    this.overloadAccounts = 0,
    this.totalRequests = 0,
    this.totalInputTokens = 0,
    this.totalOutputTokens = 0,
    this.totalCacheCreationTokens = 0,
    this.totalCacheReadTokens = 0,
    this.totalTokens = 0,
    this.totalCost = 0,
    this.totalActualCost = 0,
    this.todayRequests = 0,
    this.todayInputTokens = 0,
    this.todayOutputTokens = 0,
    this.todayTokens = 0,
    this.todayCost = 0,
    this.todayActualCost = 0,
    this.averageDurationMs = 0,
    this.uptime = 0,
    this.rpm = 0,
    this.tpm = 0,
    this.topModels = const [],
    this.dailyUsage = const [],
    this.userRanking = const [],
  });

  static double _num(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v is num) return v.toDouble();
    }
    return 0;
  }

  static int _int(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v is num) return v.toInt();
    }
    return 0;
  }

  /// 由用户级 stats / trend / models 三段响应拼装。
  factory DashboardData.fromParts({
    Map<String, dynamic>? stats,
    Map<String, dynamic>? trend,
    Map<String, dynamic>? models,
  }) {
    final s = stats ?? const {};
    final trendList = (trend?['trend'] ?? trend?['daily_usage']) as List? ?? const [];
    final modelList = (models?['models'] ?? models?['top_models']) as List? ?? const [];

    return DashboardData(
      isAdmin: false,
      totalBalance: _num(s, ['balance', 'total_balance']),
      todayUsage: _num(s, ['today_cost', 'today_usage', 'today_spend']),
      weekUsage: _num(s, ['week_cost', 'week_usage', 'week_spend']),
      monthUsage: _num(s, ['month_cost', 'month_usage', 'month_spend']),
      totalRequests: _int(s, ['total_requests', 'today_requests']),
      averageDurationMs: _num(s, ['avg_duration', 'avg_latency', 'average_duration_ms']),
      dailyUsage: trendList
          .whereType<Map<String, dynamic>>()
          .map(DailyUsage.fromJson)
          .toList(),
      topModels: modelList
          .whereType<Map<String, dynamic>>()
          .map(ModelUsage.fromJson)
          .toList(),
    );
  }

  /// 由管理员级 stats / trend / models / ranking 四段响应拼装。
  /// 对齐 sub2api Web 版 DashboardView，端点 /api/v1/admin/dashboard/*
  factory DashboardData.fromAdminParts({
    Map<String, dynamic>? stats,
    Map<String, dynamic>? trend,
    Map<String, dynamic>? models,
    Map<String, dynamic>? ranking,
  }) {
    final s = stats ?? const {};
    final trendList = (trend?['trend'] ?? trend?['daily_usage']) as List? ?? const [];
    final modelList = (models?['models'] ?? models?['top_models']) as List? ?? const [];
    final rankingList = (ranking?['ranking']) as List? ?? const [];

    return DashboardData(
      isAdmin: true,
      // 用户统计
      totalUsers: _int(s, ['total_users']),
      todayNewUsers: _int(s, ['today_new_users']),
      activeUsers: _int(s, ['active_users', 'hourly_active_users']),
      // API Key 统计
      totalApiKeys: _int(s, ['total_api_keys']),
      activeApiKeys: _int(s, ['active_api_keys']),
      // 账号统计
      totalAccounts: _int(s, ['total_accounts']),
      normalAccounts: _int(s, ['normal_accounts']),
      errorAccounts: _int(s, ['error_accounts']),
      ratelimitAccounts: _int(s, ['ratelimit_accounts']),
      overloadAccounts: _int(s, ['overload_accounts']),
      // 累计 Token 使用统计
      totalRequests: _int(s, ['total_requests']),
      totalInputTokens: _int(s, ['total_input_tokens']),
      totalOutputTokens: _int(s, ['total_output_tokens']),
      totalCacheCreationTokens: _int(s, ['total_cache_creation_tokens']),
      totalCacheReadTokens: _int(s, ['total_cache_read_tokens']),
      totalTokens: _int(s, ['total_tokens']),
      totalCost: _num(s, ['total_cost']),
      totalActualCost: _num(s, ['total_actual_cost']),
      // 今日 Token 使用统计
      todayRequests: _int(s, ['today_requests']),
      todayInputTokens: _int(s, ['today_input_tokens']),
      todayOutputTokens: _int(s, ['today_output_tokens']),
      todayTokens: _int(s, ['today_tokens']),
      todayCost: _num(s, ['today_cost']),
      todayActualCost: _num(s, ['today_actual_cost']),
      // 系统运行 & 性能
      averageDurationMs: _num(s, ['average_duration_ms']),
      uptime: _int(s, ['uptime']),
      rpm: _int(s, ['rpm']),
      tpm: _int(s, ['tpm']),
      // 共用
      dailyUsage: trendList
          .whereType<Map<String, dynamic>>()
          .map(DailyUsage.fromJson)
          .toList(),
      topModels: modelList
          .whereType<Map<String, dynamic>>()
          .map(ModelUsage.fromJson)
          .toList(),
      userRanking: rankingList
          .whereType<Map<String, dynamic>>()
          .map(UserRankingItem.fromJson)
          .toList(),
    );
  }

  /// 兼容旧的单一响应解析。
  factory DashboardData.fromJson(Map<String, dynamic> json) =>
      DashboardData.fromParts(stats: json, trend: json, models: json);
}

class ModelUsage {
  final String model;
  final int requests;
  final double cost;

  const ModelUsage({required this.model, required this.requests, required this.cost});

  factory ModelUsage.fromJson(Map<String, dynamic> json) {
    return ModelUsage(
      model: json['model'] as String? ?? '',
      requests: (json['requests'] as num?)?.toInt() ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DailyUsage {
  final DateTime date;
  final int requests;
  final double cost;
  final int inputTokens;
  final int outputTokens;

  const DailyUsage({
    required this.date,
    required this.requests,
    required this.cost,
    required this.inputTokens,
    required this.outputTokens,
  });

  factory DailyUsage.fromJson(Map<String, dynamic> json) {
    return DailyUsage(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      requests: (json['requests'] as num?)?.toInt() ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      inputTokens: (json['input_tokens'] as num?)?.toInt() ?? 0,
      outputTokens: (json['output_tokens'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 用户消费排行榜条目。
/// 对应后端 GET /api/v1/admin/dashboard/users-ranking 响应的 ranking[] 元素。
class UserRankingItem {
  final int userId;
  final String email;
  final String username;
  final double cost;
  final double actualCost;
  final int requests;
  final int tokens;

  const UserRankingItem({
    required this.userId,
    required this.email,
    this.username = '',
    required this.cost,
    this.actualCost = 0,
    required this.requests,
    required this.tokens,
  });

  /// 显示名：优先用 username，否则取 email 前缀
  String get displayName {
    if (username.isNotEmpty) return username;
    if (email.isNotEmpty) {
      final at = email.indexOf('@');
      return at > 0 ? email.substring(0, at) : email;
    }
    return 'User #$userId';
  }

  factory UserRankingItem.fromJson(Map<String, dynamic> json) {
    return UserRankingItem(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      actualCost: (json['actual_cost'] as num?)?.toDouble() ?? 0,
      requests: (json['requests'] as num?)?.toInt() ?? 0,
      tokens: (json['tokens'] as num?)?.toInt() ?? (json['total_tokens'] as num?)?.toInt() ?? 0,
    );
  }
}
