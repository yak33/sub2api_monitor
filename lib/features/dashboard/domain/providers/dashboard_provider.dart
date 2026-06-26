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
    // 发起并行的网络请求，优化页面加载性能，并将可能出错的图表请求做安全防崩溃捕获
    final statsFuture = apiClient.getAdminDashboardStats();
    final trendFuture = apiClient.getAdminDashboardTrend().catchError((_) => <String, dynamic>{});
    final modelsFuture = apiClient.getAdminDashboardModels().catchError((_) => <String, dynamic>{});
    final rankingFuture = apiClient.getUsersRanking(limit: 12).catchError((_) => <String, dynamic>{});
    final usersTrendFuture = apiClient.getUserUsageTrend(limit: 12).catchError((_) => <String, dynamic>{});
    // 拉取前 100 名活跃用户用于做 ID -> Username 的前端动态映射
    final usersListFuture = apiClient.getAdminUsers(pageSize: 100).catchError((_) => <String, dynamic>{});

    final results = await Future.wait([
      statsFuture,
      trendFuture,
      modelsFuture,
      rankingFuture,
      usersTrendFuture,
      usersListFuture,
    ]);

    final statsResp = results[0];
    final trendResp = results[1];
    final modelsResp = results[2];
    
    // 剥离外信封并复制为可修改的 Map
    final rawRanking = results[3];
    final Map<String, dynamic> rankingResp = Map<String, dynamic>.from(
      (rawRanking['data'] as Map<String, dynamic>?) ?? rawRanking
    );
    
    final usersTrendResp = results[4];
    final usersListResp = results[5];

    // 1. 在前端内存中构建用户 ID 与 Username 的 Key-Value 映射
    final userMap = <int, String>{};
    try {
      final listData = (usersListResp['data'] as Map<String, dynamic>?) ?? usersListResp;
      final items = listData['items'] as List?;
      if (items != null) {
        for (var item in items) {
          if (item is Map<String, dynamic>) {
            final id = (item['id'] as num?)?.toInt();
            final name = item['username']?.toString() ?? '';
            if (id != null && name.isNotEmpty) {
              userMap[id] = name;
            }
          }
        }
      }
    } catch (_) {}

    // 2. 将获取到的用户名动态缝合到消费榜的 DTO 数据中
    try {
      final rankingList = rankingResp['ranking'] as List?;
      if (rankingList != null) {
        final mergedRanking = <Map<String, dynamic>>[];
        for (var item in rankingList) {
          if (item is Map<String, dynamic>) {
            final mutableItem = Map<String, dynamic>.from(item);
            final uid = (mutableItem['user_id'] as num?)?.toInt();
            if (uid != null && userMap.containsKey(uid)) {
              mutableItem['username'] = userMap[uid];
            }
            mergedRanking.add(mutableItem);
          }
        }
        rankingResp['ranking'] = mergedRanking;
      }
    } catch (_) {}

    return DashboardData.fromAdminParts(
      stats: _unwrap(statsResp),
      trend: _unwrap(trendResp),
      models: _unwrap(modelsResp),
      ranking: rankingResp, // 已完成前端用户名动态缝合
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
