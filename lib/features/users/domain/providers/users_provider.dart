import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../entities/admin_user.dart';

/// 用户列表状态：保留搜索/过滤条件与分页游标，便于翻页与刷新。
class UsersListState {
  final List<AdminUser> items;
  final int total;
  final int page;
  final int pages;
  final String search;
  final String status;
  final bool isLoading;
  final String? error;

  const UsersListState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pages = 1,
    this.search = '',
    this.status = '',
    this.isLoading = false,
    this.error,
  });

  UsersListState copyWith({
    List<AdminUser>? items,
    int? total,
    int? page,
    int? pages,
    String? search,
    String? status,
    bool? isLoading,
    String? error,
  }) {
    return UsersListState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      search: search ?? this.search,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final usersListProvider =
    StateNotifierProvider<UsersListNotifier, UsersListState>((ref) {
  return UsersListNotifier(ref);
});

class UsersListNotifier extends StateNotifier<UsersListState> {
  final Ref _ref;
  static const _pageSize = 20;

  UsersListNotifier(this._ref) : super(const UsersListState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(apiClientProvider);
      final resp = await api.getAdminUsers(
        page: state.page,
        pageSize: _pageSize,
        search: state.search.isEmpty ? null : state.search,
        status: state.status.isEmpty ? null : state.status,
      );
      final data = (resp['data'] as Map<String, dynamic>?) ?? resp;
      final page = AdminUserPage.fromJson(data);
      state = state.copyWith(
        items: page.items,
        total: page.total,
        pages: page.pages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 搜索（重置到第 1 页）。
  Future<void> search(String keyword) async {
    state = state.copyWith(search: keyword, page: 1);
    await _load();
  }

  /// 按状态过滤（重置到第 1 页）。
  Future<void> filterByStatus(String status) async {
    state = state.copyWith(status: status, page: 1);
    await _load();
  }

  Future<void> goToPage(int page) async {
    state = state.copyWith(page: page);
    await _load();
  }

  Future<void> refresh() => _load();

  // ── 写操作 ──

  Future<void> createUser(Map<String, dynamic> data) async {
    final api = _ref.read(apiClientProvider);
    await api.createAdminUser(data);
    await _load();
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    final api = _ref.read(apiClientProvider);
    await api.updateAdminUser(id, data);
    await _load();
  }

  Future<void> deleteUser(int id) async {
    final api = _ref.read(apiClientProvider);
    await api.deleteAdminUser(id);
    await _load();
  }

  Future<void> adjustBalance(
    int id, {
    required double balance,
    required String operation,
    String? notes,
  }) async {
    final api = _ref.read(apiClientProvider);
    await api.updateUserBalance(id, balance: balance, operation: operation, notes: notes);
    await _load();
  }
}

/// 单个用户详情（按需加载，用于详情页）。
final adminUserDetailProvider =
    FutureProvider.family<AdminUser, int>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.getAdminUser(id);
  final data = (resp['data'] as Map<String, dynamic>?) ?? resp;
  return AdminUser.fromJson(data);
});

/// 用户用量统计（按需加载，用于详情页）。
final adminUserUsageProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.getAdminUserUsage(id);
  return (resp['data'] as Map<String, dynamic>?) ?? resp;
});
