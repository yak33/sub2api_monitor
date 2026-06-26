import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/datasources/remote/api_client.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../entities/dashboard_data.dart';

final dashboardProvider = AsyncNotifierProvider<DashboardNotifier, DashboardData>(() {
  return DashboardNotifier();
});

/// 仪表盘数据 Notifier。
///
/// 数据获取策略（对齐 sub2api Web 版）：
/// 1. 若当前用户为 admin，优先调用管理员端点 /api/v1/admin/dashboard/*
/// 2. 管理员端点失败（如 403 降权、网络异常）时，自动降级到用户级端点
/// 3. 普通用户直接走用户级端点 /api/v1/usage/dashboard/*
class DashboardNotifier extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    return _fetchDashboard();
  }

  Future<DashboardData> _fetchDashboard() async {
    final apiClient = ref.read(apiClientProvider);
    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull?.user;

    if (user?.isAdmin ?? false) {
      try {
        return await _fetchAdminDashboard(apiClient);
      } catch (_) {
        // 管理员端点不可用（降权 / 预聚合未就绪），降级到用户级
        return _fetchUserDashboard(apiClient);
      }
    }
    return _fetchUserDashboard(apiClient);
  }

  /// 管理员级仪表盘：对齐 sub2api Web DashboardView。
  Future<DashboardData> _fetchAdminDashboard(ApiClient apiClient) async {
    final statsResp = await apiClient.getAdminDashboardStats();

    Map<String, dynamic> trendResp = const {};
    Map<String, dynamic> modelsResp = const {};
    Map<String, dynamic> rankingResp = const {};
    Map<String, dynamic> usersTrendResp = const {};
    try {
      trendResp = await apiClient.getAdminDashboardTrend();
    } catch (_) {}
    try {
      modelsResp = await apiClient.getAdminDashboardModels();
    } catch (_) {}
    try {
      rankingResp = await apiClient.getUsersRanking(limit: 12);
    } catch (_) {}
    try {
      usersTrendResp = await apiClient.getUserUsageTrend(limit: 12);
    } catch (_) {}

    return DashboardData.fromAdminParts(
      stats: _unwrap(statsResp),
      trend: _unwrap(trendResp),
      models: _unwrap(modelsResp),
      ranking: _unwrap(rankingResp),
      usersTrend: _unwrap(usersTrendResp),
    );
  }

  /// 用户级仪表盘：个人监控。
  Future<DashboardData> _fetchUserDashboard(ApiClient apiClient) async {
    final statsResp = await apiClient.getDashboard();

    Map<String, dynamic> trendResp = const {};
    Map<String, dynamic> modelsResp = const {};
    try {
      trendResp = await apiClient.getDashboardTrend();
    } catch (_) {}
    try {
      modelsResp = await apiClient.getDashboardModels();
    } catch (_) {}

    return DashboardData.fromParts(
      stats: _unwrap(statsResp),
      trend: _unwrap(trendResp),
      models: _unwrap(modelsResp),
    );
  }

  /// 剥离外层 {data: {...}} 信封，兼容裸响应。
  Map<String, dynamic> _unwrap(Map<String, dynamic> r) =>
      (r['data'] as Map<String, dynamic>?) ?? r;

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchDashboard());
  }
}
