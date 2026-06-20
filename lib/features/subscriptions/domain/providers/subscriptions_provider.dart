import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../entities/admin_subscription.dart';

/// 订阅列表状态：保留分页游标与过滤条件。
class SubscriptionsListState {
  final List<AdminSubscription> items;
  final int total;
  final int page;
  final int pages;
  final bool isLoading;
  final String? error;
  // 过滤条件
  final int? filterUserId;
  final int? filterGroupId;
  final String? filterStatus;

  const SubscriptionsListState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pages = 1,
    this.isLoading = false,
    this.error,
    this.filterUserId,
    this.filterGroupId,
    this.filterStatus,
  });

  SubscriptionsListState copyWith({
    List<AdminSubscription>? items,
    int? total,
    int? page,
    int? pages,
    bool? isLoading,
    String? error,
    int? filterUserId,
    int? filterGroupId,
    String? filterStatus,
  }) =>
      SubscriptionsListState(
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        pages: pages ?? this.pages,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        filterUserId: filterUserId ?? this.filterUserId,
        filterGroupId: filterGroupId ?? this.filterGroupId,
        filterStatus: filterStatus ?? this.filterStatus,
      );
}

final subscriptionsListProvider = StateNotifierProvider<SubscriptionsListNotifier,
    SubscriptionsListState>((ref) {
  return SubscriptionsListNotifier(ref);
});

class SubscriptionsListNotifier extends StateNotifier<SubscriptionsListState> {
  final Ref _ref;
  static const _pageSize = 20;

  SubscriptionsListNotifier(this._ref) : super(const SubscriptionsListState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(apiClientProvider);
      final resp = await api.getAdminSubscriptions(
        page: state.page,
        pageSize: _pageSize,
        userId: state.filterUserId,
        groupId: state.filterGroupId,
        status: state.filterStatus,
      );
      final data = (resp['data'] as Map<String, dynamic>?) ?? resp;
      final items = (data['items'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(AdminSubscription.fromJson)
              .toList() ??
          const <AdminSubscription>[];
      state = state.copyWith(
        items: items,
        total: (data['total'] as num?)?.toInt() ?? 0,
        page: (data['page'] as num?)?.toInt() ?? state.page,
        pages: (data['pages'] as num?)?.toInt() ?? state.pages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 按状态过滤（重置到第 1 页）。
  Future<void> filterByStatus(String? status) async {
    state = state.copyWith(filterStatus: status, page: 1);
    await _load();
  }

  Future<void> goToPage(int page) async {
    state = state.copyWith(page: page);
    await _load();
  }

  Future<void> refresh() => _load();

  // ── 写操作 ──

  /// 分配订阅给单个用户。
  Future<AdminSubscription> assign({
    required int userId,
    required int groupId,
    int? validityDays,
    String? notes,
  }) async {
    final api = _ref.read(apiClientProvider);
    final resp = await api.assignSubscription(
      userId: userId,
      groupId: groupId,
      validityDays: validityDays,
      notes: notes,
    );
    final data = (resp['data'] as Map<String, dynamic>?) ?? resp;
    final sub = AdminSubscription.fromJson(data);
    await _load();
    return sub;
  }

  /// 批量分配订阅。
  Future<BulkAssignResult> bulkAssign({
    required List<int> userIds,
    required int groupId,
    int? validityDays,
    String? notes,
  }) async {
    final api = _ref.read(apiClientProvider);
    final resp = await api.bulkAssignSubscriptions(
      userIds: userIds,
      groupId: groupId,
      validityDays: validityDays,
      notes: notes,
    );
    final data = (resp['data'] as Map<String, dynamic>?) ?? resp;
    final result = BulkAssignResult.fromJson(data);
    await _load();
    return result;
  }

  /// 延长/缩短有效期。days 可为负数，范围 [-36500, 36500]。
  Future<AdminSubscription> extend(int id, int days) async {
    final api = _ref.read(apiClientProvider);
    final resp = await api.extendSubscription(id, days);
    final data = (resp['data'] as Map<String, dynamic>?) ?? resp;
    final sub = AdminSubscription.fromJson(data);
    await _load();
    return sub;
  }

  /// 重置用量配额。
  Future<AdminSubscription> resetQuota(
    int id, {
    bool daily = false,
    bool weekly = false,
    bool monthly = false,
  }) async {
    final api = _ref.read(apiClientProvider);
    final resp = await api.resetSubscriptionQuota(
      id,
      daily: daily,
      weekly: weekly,
      monthly: monthly,
    );
    final data = (resp['data'] as Map<String, dynamic>?) ?? resp;
    final sub = AdminSubscription.fromJson(data);
    await _load();
    return sub;
  }

  /// 撤销订阅。
  Future<void> revoke(int id) async {
    final api = _ref.read(apiClientProvider);
    await api.revokeSubscription(id);
    await _load();
  }
}

/// 指定用户的订阅列表（异步加载，用于用户详情页等场景）。
final userSubscriptionsProvider =
    FutureProvider.family<List<AdminSubscription>, int>((ref, userId) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.getSubscriptionsByUser(userId);
  final data = (resp['data'] as Map<String, dynamic>?) ?? resp;
  final items = (data['subscriptions'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map(AdminSubscription.fromJson)
          .toList() ??
      const <AdminSubscription>[];
  return items;
});
