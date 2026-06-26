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

  // ── 管理员专属：用户用量趋势（最近使用 Top 12）──
  final UserUsageTrend userTrend;

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
    this.userTrend = const UserUsageTrend(),
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
    Map<String, dynamic>? usersTrend,
  }) {
    final s = stats ?? const {};
    final trendList = (trend?['trend'] ?? trend?['daily_usage']) as List? ?? const [];
    final modelList = (models?['models'] ?? models?['top_models']) as List? ?? const [];
    final rankingList = (ranking?['ranking']) as List? ?? const [];
    final usersTrendList = (usersTrend?['trend']) as List? ?? const [];

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
      userTrend: UserUsageTrend.fromPoints(usersTrendList),
    );
  }

  /// 兼容旧的单一响应解析。
  factory DashboardData.fromJson(Map<String, dynamic> json) =>
      DashboardData.fromParts(stats: json, trend: json, models: json);
}

class ModelUsage {
  final String model;
  final int requests;
  final int tokens;
  final double cost;
  final double actualCost;

  const ModelUsage({
    required this.model,
    required this.requests,
    this.tokens = 0,
    required this.cost,
    this.actualCost = 0,
  });

  factory ModelUsage.fromJson(Map<String, dynamic> json) {
    return ModelUsage(
      model: json['model'] as String? ?? '',
      requests: (json['requests'] as num?)?.toInt() ?? 0,
      tokens: (json['total_tokens'] as num?)?.toInt() ?? (json['tokens'] as num?)?.toInt() ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      actualCost: (json['actual_cost'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// 用量趋势单点。
///
/// 对齐 sub2api Web 版 TokenUsageTrend：除请求/成本外，细分四类 Token
/// （输入 / 输出 / 缓存写入 / 缓存读取），缓存命中率由前端按
/// `cache_read / (input + cache_read + cache_creation)` 实时计算，非服务端字段。
class DailyUsage {
  final DateTime date;
  final int requests;
  final double cost;
  final double actualCost;
  final int inputTokens;
  final int outputTokens;
  final int cacheCreationTokens;
  final int cacheReadTokens;

  const DailyUsage({
    required this.date,
    required this.requests,
    required this.cost,
    this.actualCost = 0,
    required this.inputTokens,
    required this.outputTokens,
    this.cacheCreationTokens = 0,
    this.cacheReadTokens = 0,
  });

  /// 四类 Token 合计，用于趋势图纵轴量纲。
  int get totalTokens => inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens;

  /// 缓存命中率（百分比，0~100）。分母为可命中的 prompt 侧 Token。
  double get cacheHitRate {
    final promptTokens = inputTokens + cacheReadTokens + cacheCreationTokens;
    if (promptTokens <= 0) return 0;
    return cacheReadTokens / promptTokens * 100;
  }

  factory DailyUsage.fromJson(Map<String, dynamic> json) {
    return DailyUsage(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      requests: (json['requests'] as num?)?.toInt() ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      actualCost: (json['actual_cost'] as num?)?.toDouble() ?? 0,
      inputTokens: (json['input_tokens'] as num?)?.toInt() ?? 0,
      outputTokens: (json['output_tokens'] as num?)?.toInt() ?? 0,
      cacheCreationTokens: (json['cache_creation_tokens'] as num?)?.toInt() ?? 0,
      cacheReadTokens: (json['cache_read_tokens'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 用户用量趋势（管理员专属，对齐 Web 版「最近使用 Top 12」）。
///
/// 后端 GET /api/v1/admin/dashboard/users-trend 返回**扁平**的点列表，
/// 每点形如 `{user_id, username, email, date, tokens}`；此处按 user_id 聚合为
/// 「统一时间轴 + 每用户一条序列」的矩阵结构，UI 直接消费、无需再做分组。
class UserUsageTrend {
  /// 升序去重后的时间标签，作为所有序列共享的 X 轴。
  final List<String> dates;

  /// 每个用户一条序列，已按总用量降序（图例与高亮顺序更符合直觉）。
  final List<UserTrendSeries> series;

  const UserUsageTrend({this.dates = const [], this.series = const []});

  bool get isEmpty => series.isEmpty || dates.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// 由扁平点列表聚合。缺失的 (用户, 时间) 组合补 0，保证各序列等长对齐。
  factory UserUsageTrend.fromPoints(List<dynamic> points) {
    final dateSet = <String>{};
    // user_id -> (显示名, date -> tokens)
    final groups = <int, _UserAccumulator>{};

    for (final raw in points) {
      if (raw is! Map<String, dynamic>) continue;
      final date = raw['date'] as String? ?? '';
      if (date.isEmpty) continue;
      dateSet.add(date);

      final userId = (raw['user_id'] as num?)?.toInt() ?? 0;
      final tokens = (raw['tokens'] as num?)?.toInt() ??
          (raw['total_tokens'] as num?)?.toInt() ??
          0;
      groups
          .putIfAbsent(userId, () => _UserAccumulator(_displayName(raw, userId)))
          .points[date] = tokens;
    }

    final sortedDates = dateSet.toList()..sort();
    final series = groups.entries
        .map((e) => UserTrendSeries(
              userId: e.key,
              name: e.value.name,
              values: sortedDates.map((d) => e.value.points[d] ?? 0).toList(),
            ))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return UserUsageTrend(dates: sortedDates, series: series);
  }

  /// 显示名：username 优先，其次 email，最后兜底 `User #id`。
  static String _displayName(Map<String, dynamic> json, int userId) {
    final username = (json['username'] as String? ?? '').trim();
    if (username.isNotEmpty) return username;
    final email = (json['email'] as String? ?? '').trim();
    if (email.isNotEmpty) {
      final at = email.indexOf('@');
      return at > 0 ? email.substring(0, at) : email;
    }
    return 'User #$userId';
  }
}

class _UserAccumulator {
  final String name;
  final Map<String, int> points = {};
  _UserAccumulator(this.name);
}

/// 单个用户的趋势序列，[values] 与 [UserUsageTrend.dates] 等长对齐。
class UserTrendSeries {
  final int userId;
  final String name;
  final List<int> values;

  const UserTrendSeries({required this.userId, required this.name, required this.values});

  int get total => values.fold(0, (sum, v) => sum + v);
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

  /// 显示名：优先用 username，否则取完整 email
  String get displayName {
    if (username.isNotEmpty) return username;
    if (email.isNotEmpty) return email;
    return 'User #$userId';
  }

  factory UserRankingItem.fromJson(Map<String, dynamic> json) {
    return UserRankingItem(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      cost: (json['cost'] as num?)?.toDouble() ?? (json['actual_cost'] as num?)?.toDouble() ?? 0,
      actualCost: (json['actual_cost'] as num?)?.toDouble() ?? 0,
      requests: (json['requests'] as num?)?.toInt() ?? 0,
      tokens: (json['tokens'] as num?)?.toInt() ?? (json['total_tokens'] as num?)?.toInt() ?? 0,
    );
  }
}
