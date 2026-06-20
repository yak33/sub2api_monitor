import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../entities/admin_account.dart';

/// 账号列表状态。
class AccountsListState {
  final List<AdminAccount> items;
  final int total;
  final int page;
  final int pages;
  final bool isLoading;
  final String? error;
  final String? filterPlatform;
  final String? filterStatus;

  const AccountsListState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pages = 1,
    this.isLoading = false,
    this.error,
    this.filterPlatform,
    this.filterStatus,
  });

  AccountsListState copyWith({
    List<AdminAccount>? items,
    int? total,
    int? page,
    int? pages,
    bool? isLoading,
    String? error,
    String? filterPlatform,
    String? filterStatus,
  }) =>
      AccountsListState(
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        pages: pages ?? this.pages,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        filterPlatform: filterPlatform ?? this.filterPlatform,
        filterStatus: filterStatus ?? this.filterStatus,
      );
}

final accountsListProvider =
    StateNotifierProvider<AccountsListNotifier, AccountsListState>((ref) {
  return AccountsListNotifier(ref);
});

class AccountsListNotifier extends StateNotifier<AccountsListState> {
  final Ref _ref;
  static const _pageSize = 20;

  AccountsListNotifier(this._ref) : super(const AccountsListState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(apiClientProvider);
      final resp = await api.getAdminAccounts(
        page: state.page,
        pageSize: _pageSize,
        platform: state.filterPlatform,
        status: state.filterStatus,
      );
      final data = (resp['data'] as Map<String, dynamic>?) ?? resp;
      final items = (data['items'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(AdminAccount.fromJson)
              .toList() ??
          const <AdminAccount>[];
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

  Future<void> filterByPlatform(String? platform) async {
    state = state.copyWith(filterPlatform: platform, page: 1);
    await _load();
  }

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

  Future<void> clearError(int id) async {
    final api = _ref.read(apiClientProvider);
    await api.clearAccountError(id);
    await _load();
  }

  Future<void> recoverState(int id) async {
    final api = _ref.read(apiClientProvider);
    await api.recoverAccountState(id);
    await _load();
  }

  Future<void> refreshAccount(int id) async {
    final api = _ref.read(apiClientProvider);
    await api.refreshAdminAccount(id);
    await _load();
  }

  Future<void> deleteAccount(int id) async {
    final api = _ref.read(apiClientProvider);
    await api.deleteAdminAccount(id);
    await _load();
  }

  Future<void> testAccount(int id) async {
    final api = _ref.read(apiClientProvider);
    await api.testAdminAccount(id);
  }
}
