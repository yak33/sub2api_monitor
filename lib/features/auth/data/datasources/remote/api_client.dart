import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../local/auth_storage.dart';
import 'auth_interceptor.dart';

/// Sub2API 网关 HTTP 客户端。
///
/// 端点路径以 sub2api 后端真实路由为准。
/// 个人监控优先使用用户级端点（/api/v1/usage/dashboard/*、/api/v1/keys 等），
/// 均走 JWT 鉴权。
class ApiClient {
  late final Dio _dio;
  final String baseUrl;

  ApiClient({
    required this.baseUrl,
    required AuthStorage storage,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(AuthInterceptor(storage: storage, dio: _dio));

    // 仅调试期记录请求概要；不打印 header/body，避免泄露密码与 Token
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }

  // ── Auth ──
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/api/v1/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  /// 获取当前登录用户。sub2api 真实端点为 /api/v1/auth/me（响应内嵌 user 字段）
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/api/v1/auth/me');
    return response.data;
  }

  // ── Dashboard（用户级）──
  /// 个人仪表盘汇总。真实端点 /api/v1/usage/dashboard/stats
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dio.get('/api/v1/usage/dashboard/stats');
    return response.data;
  }

  /// 个人用量趋势（用于趋势图）。真实端点 /api/v1/usage/dashboard/trend
  Future<Map<String, dynamic>> getDashboardTrend({String granularity = 'day'}) async {
    final response = await _dio.get(
      '/api/v1/usage/dashboard/trend',
      queryParameters: {'granularity': granularity},
    );
    return response.data;
  }

  /// 个人模型用量分布（用于 Top 模型）。真实端点 /api/v1/usage/dashboard/models
  Future<Map<String, dynamic>> getDashboardModels() async {
    final response = await _dio.get('/api/v1/usage/dashboard/models');
    return response.data;
  }

  // ── Dashboard（管理员级，需 admin 角色；普通用户访问返回 403）──
  // 对齐 sub2api Web 版 DashboardView，端点详见 backend/internal/handler/admin/dashboard_handler.go

  /// 管理员仪表盘汇总统计。GET /api/v1/admin/dashboard/stats
  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    final response = await _dio.get('/api/v1/admin/dashboard/stats');
    return response.data;
  }

  /// 管理员用量趋势。GET /api/v1/admin/dashboard/trend
  Future<Map<String, dynamic>> getAdminDashboardTrend({
    String? startDate,
    String? endDate,
    String granularity = 'day',
  }) async {
    final qp = <String, dynamic>{'granularity': granularity};
    if (startDate != null) qp['start_date'] = startDate;
    if (endDate != null) qp['end_date'] = endDate;
    final response = await _dio.get('/api/v1/admin/dashboard/trend', queryParameters: qp);
    return response.data;
  }

  /// 管理员模型用量统计。GET /api/v1/admin/dashboard/models
  Future<Map<String, dynamic>> getAdminDashboardModels({
    String? startDate,
    String? endDate,
  }) async {
    final qp = <String, dynamic>{};
    if (startDate != null) qp['start_date'] = startDate;
    if (endDate != null) qp['end_date'] = endDate;
    final response = await _dio.get('/api/v1/admin/dashboard/models', queryParameters: qp);
    return response.data;
  }

  /// 用户消费排行榜。GET /api/v1/admin/dashboard/users-ranking
  /// Query params: start_date, end_date (YYYY-MM-DD), limit (default 12, max 50)
  Future<Map<String, dynamic>> getUsersRanking({
    String? startDate,
    String? endDate,
    int limit = 12,
  }) async {
    final qp = <String, dynamic>{'limit': limit};
    if (startDate != null) qp['start_date'] = startDate;
    if (endDate != null) qp['end_date'] = endDate;
    final response = await _dio.get('/api/v1/admin/dashboard/users-ranking', queryParameters: qp);
    return response.data;
  }

  /// 用户用量趋势（最近使用 Top N，按用户分组的时间序列）。
  /// GET /api/v1/admin/dashboard/users-trend
  /// Query params: start_date, end_date (YYYY-MM-DD), granularity (day/hour), limit (default 12)
  Future<Map<String, dynamic>> getUserUsageTrend({
    String? startDate,
    String? endDate,
    String granularity = 'hour',
    int limit = 12,
  }) async {
    final qp = <String, dynamic>{'granularity': granularity, 'limit': limit};
    if (startDate != null) qp['start_date'] = startDate;
    if (endDate != null) qp['end_date'] = endDate;
    final response = await _dio.get('/api/v1/admin/dashboard/users-trend', queryParameters: qp);
    return response.data;
  }

  // ── Usage ──
  Future<Map<String, dynamic>> getUsage({
    int page = 1,
    int pageSize = 20,
    String? startDate,
    String? endDate,
    String? model,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (startDate != null) queryParameters['start_date'] = startDate;
    if (endDate != null) queryParameters['end_date'] = endDate;
    if (model != null) queryParameters['model'] = model;

    final response = await _dio.get('/api/v1/usage', queryParameters: queryParameters);
    return response.data;
  }

  /// 用量日志列表。个人监控使用用户级 /api/v1/usage（分页返回 {items,total,page,page_size,pages}）
  Future<Map<String, dynamic>> getUsageLogs({
    int page = 1,
    int pageSize = 20,
    String? startDate,
    String? endDate,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (startDate != null) queryParameters['start_date'] = startDate;
    if (endDate != null) queryParameters['end_date'] = endDate;

    final response = await _dio.get('/api/v1/usage', queryParameters: queryParameters);
    return response.data;
  }

  // ── API Keys（真实路径 /api/v1/keys）──
  Future<Map<String, dynamic>> getApiKeys() async {
    final response = await _dio.get('/api/v1/keys');
    return response.data;
  }

  Future<Map<String, dynamic>> createApiKey(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/keys', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateApiKey(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/v1/keys/$id', data: data);
    return response.data;
  }

  Future<void> deleteApiKey(int id) async {
    await _dio.delete('/api/v1/keys/$id');
  }

  // ── Subscriptions ──
  Future<Map<String, dynamic>> getSubscriptions() async {
    final response = await _dio.get('/api/v1/subscriptions');
    return response.data;
  }

  // ── Announcements ──
  Future<Map<String, dynamic>> getAnnouncements() async {
    final response = await _dio.get('/api/v1/announcements');
    return response.data;
  }

  // ── Redeem ──
  Future<Map<String, dynamic>> redeemCode(String code) async {
    final response = await _dio.post('/api/v1/redeem', data: {'code': code});
    return response.data;
  }

  // ── Channel Monitor（用户级，真实路径为复数 /api/v1/channel-monitors）──
  Future<Map<String, dynamic>> getChannelMonitor() async {
    final response = await _dio.get('/api/v1/channel-monitors');
    return response.data;
  }

  // ── Admin Accounts ──

  /// 账号列表（分页 + 过滤）。GET /api/v1/admin/accounts
  Future<Map<String, dynamic>> getAdminAccounts({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? platform,
    String? status,
    String? type,
    int? groupId,
    String sortBy = 'id',
    String sortOrder = 'desc',
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };
    if (search != null && search.isNotEmpty) qp['search'] = search;
    if (platform != null && platform.isNotEmpty) qp['platform'] = platform;
    if (status != null && status.isNotEmpty) qp['status'] = status;
    if (type != null && type.isNotEmpty) qp['type'] = type;
    if (groupId != null) qp['group_id'] = groupId;
    final response = await _dio.get('/api/v1/admin/accounts', queryParameters: qp);
    return response.data;
  }

  /// 账号详情。GET /api/v1/admin/accounts/:id
  Future<Map<String, dynamic>> getAdminAccount(int id) async {
    final response = await _dio.get('/api/v1/admin/accounts/$id');
    return response.data;
  }

  /// 创建账号。POST /api/v1/admin/accounts
  Future<Map<String, dynamic>> createAdminAccount(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/admin/accounts', data: data);
    return response.data;
  }

  /// 更新账号。PUT /api/v1/admin/accounts/:id
  Future<Map<String, dynamic>> updateAdminAccount(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/v1/admin/accounts/$id', data: data);
    return response.data;
  }

  /// 删除账号。DELETE /api/v1/admin/accounts/:id
  Future<void> deleteAdminAccount(int id) async {
    await _dio.delete('/api/v1/admin/accounts/$id');
  }

  /// 测试账号连通性。POST /api/v1/admin/accounts/:id/test
  Future<Map<String, dynamic>> testAdminAccount(int id) async {
    final response = await _dio.post('/api/v1/admin/accounts/$id/test');
    return response.data;
  }

  /// 清除账号错误。POST /api/v1/admin/accounts/:id/clear-error
  Future<Map<String, dynamic>> clearAccountError(int id) async {
    final response = await _dio.post('/api/v1/admin/accounts/$id/clear-error');
    return response.data;
  }

  /// 恢复账号状态。POST /api/v1/admin/accounts/:id/recover-state
  Future<Map<String, dynamic>> recoverAccountState(int id) async {
    final response = await _dio.post('/api/v1/admin/accounts/$id/recover-state');
    return response.data;
  }

  /// 刷新账号。POST /api/v1/admin/accounts/:id/refresh
  Future<Map<String, dynamic>> refreshAdminAccount(int id) async {
    final response = await _dio.post('/api/v1/admin/accounts/$id/refresh');
    return response.data;
  }

  // ── Admin Users（管理员级用户管理，端点 /api/v1/admin/users）──

  /// 用户列表（分页 + 搜索/过滤）。GET /api/v1/admin/users
  Future<Map<String, dynamic>> getAdminUsers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? role,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };
    if (search != null && search.isNotEmpty) qp['search'] = search;
    if (status != null && status.isNotEmpty) qp['status'] = status;
    if (role != null && role.isNotEmpty) qp['role'] = role;
    final response = await _dio.get('/api/v1/admin/users', queryParameters: qp);
    return response.data;
  }

  /// 用户详情。GET /api/v1/admin/users/:id
  Future<Map<String, dynamic>> getAdminUser(int id) async {
    final response = await _dio.get('/api/v1/admin/users/$id');
    return response.data;
  }

  /// 创建用户。POST /api/v1/admin/users
  Future<Map<String, dynamic>> createAdminUser(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/admin/users', data: data);
    return response.data;
  }

  /// 更新用户。PUT /api/v1/admin/users/:id
  Future<Map<String, dynamic>> updateAdminUser(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/v1/admin/users/$id', data: data);
    return response.data;
  }

  /// 删除用户。DELETE /api/v1/admin/users/:id
  Future<void> deleteAdminUser(int id) async {
    await _dio.delete('/api/v1/admin/users/$id');
  }

  /// 调整用户余额（幂等）。POST /api/v1/admin/users/:id/balance
  Future<Map<String, dynamic>> updateUserBalance(
    int id, {
    required double balance,
    required String operation,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'balance': balance,
      'operation': operation,
    };
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    final response = await _dio.post('/api/v1/admin/users/$id/balance', data: body);
    return response.data;
  }

  /// 用户用量统计。GET /api/v1/admin/users/:id/usage
  Future<Map<String, dynamic>> getAdminUserUsage(int id, {String period = 'month'}) async {
    final response = await _dio.get(
      '/api/v1/admin/users/$id/usage',
      queryParameters: {'period': period},
    );
    return response.data;
  }

  // ── Admin Subscriptions ──
  /// 管理员订阅列表。GET /api/v1/admin/subscriptions
  Future<Map<String, dynamic>> getAdminSubscriptions({
    int page = 1,
    int pageSize = 20,
    int? userId,
    int? groupId,
    String? status,
    String? platform,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };
    if (userId != null) qp['user_id'] = userId;
    if (groupId != null) qp['group_id'] = groupId;
    if (status != null && status.isNotEmpty) qp['status'] = status;
    if (platform != null && platform.isNotEmpty) qp['platform'] = platform;
    final response = await _dio.get('/api/v1/admin/subscriptions', queryParameters: qp);
    return response.data;
  }

  /// 订阅详情。GET /api/v1/admin/subscriptions/:id
  Future<Map<String, dynamic>> getAdminSubscription(int id) async {
    final response = await _dio.get('/api/v1/admin/subscriptions/$id');
    return response.data;
  }

  /// 订阅用量进度。GET /api/v1/admin/subscriptions/:id/progress
  Future<Map<String, dynamic>> getAdminSubscriptionProgress(int id) async {
    final response = await _dio.get('/api/v1/admin/subscriptions/$id/progress');
    return response.data;
  }

  /// 分配订阅。POST /api/v1/admin/subscriptions/assign
  Future<Map<String, dynamic>> assignSubscription({
    required int userId,
    required int groupId,
    int? validityDays,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'group_id': groupId,
    };
    if (validityDays != null) body['validity_days'] = validityDays;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    final response = await _dio.post('/api/v1/admin/subscriptions/assign', data: body);
    return response.data;
  }

  /// 批量分配订阅。POST /api/v1/admin/subscriptions/bulk-assign
  Future<Map<String, dynamic>> bulkAssignSubscriptions({
    required List<int> userIds,
    required int groupId,
    int? validityDays,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'user_ids': userIds,
      'group_id': groupId,
    };
    if (validityDays != null) body['validity_days'] = validityDays;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    final response =
        await _dio.post('/api/v1/admin/subscriptions/bulk-assign', data: body);
    return response.data;
  }

  /// 延长/缩短订阅有效期（幂等）。POST /api/v1/admin/subscriptions/:id/extend
  Future<Map<String, dynamic>> extendSubscription(int id, int days) async {
    final response = await _dio.post(
      '/api/v1/admin/subscriptions/$id/extend',
      data: {'days': days},
    );
    return response.data;
  }

  /// 重置订阅用量配额（幂等）。POST /api/v1/admin/subscriptions/:id/reset-quota
  Future<Map<String, dynamic>> resetSubscriptionQuota(
    int id, {
    bool daily = false,
    bool weekly = false,
    bool monthly = false,
  }) async {
    final response = await _dio.post(
      '/api/v1/admin/subscriptions/$id/reset-quota',
      data: {
        'daily': daily,
        'weekly': weekly,
        'monthly': monthly,
      },
    );
    return response.data;
  }

  /// 撤销订阅。DELETE /api/v1/admin/subscriptions/:id
  Future<void> revokeSubscription(int id) async {
    await _dio.delete('/api/v1/admin/subscriptions/$id');
  }

  /// 按用户查订阅列表。GET /api/v1/admin/users/:id/subscriptions
  Future<Map<String, dynamic>> getSubscriptionsByUser(int userId) async {
    final response = await _dio.get('/api/v1/admin/users/$userId/subscriptions');
    return response.data;
  }
}
