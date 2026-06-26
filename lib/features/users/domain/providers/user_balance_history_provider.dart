import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../entities/user_balance_history.dart';

/// 用户余额变动历史记录的页面状态。
///
/// @author ZHANGCHAO
/// @date 2026/06/27
class UserBalanceHistoryState {
  final List<UserBalanceHistoryItem> items;
  final int total;
  final int page;
  final int pages;
  final double totalRecharged;
  final String type;
  final bool isLoading;
  final String? error;

  const UserBalanceHistoryState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pages = 1,
    this.totalRecharged = 0.0,
    this.type = '',
    this.isLoading = false,
    this.error,
  });

  UserBalanceHistoryState copyWith({
    List<UserBalanceHistoryItem>? items,
    int? total,
    int? page,
    int? pages,
    double? totalRecharged,
    String? type,
    bool? isLoading,
    String? error,
  }) {
    return UserBalanceHistoryState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      totalRecharged: totalRecharged ?? this.totalRecharged,
      type: type ?? this.type,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 用户余额变动历史记录（充值记录）状态管理。
///
/// 采用 `.family` 参数化提供者，每个用户的充值记录状态完全隔离。
///
/// @author ZHANGCHAO
/// @date 2026/06/27
final userBalanceHistoryProvider = StateNotifierProvider.family<
    UserBalanceHistoryNotifier, UserBalanceHistoryState, int>((ref, userId) {
  return UserBalanceHistoryNotifier(ref, userId);
});

class UserBalanceHistoryNotifier extends StateNotifier<UserBalanceHistoryState> {
  final Ref _ref;
  final int _userId;
  static const _pageSize = 20;

  UserBalanceHistoryNotifier(this._ref, this._userId)
      : super(const UserBalanceHistoryState()) {
    load();
  }

  /// 加载当前筛选条件和页码下的变动历史数据。
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(apiClientProvider);
      final resp = await api.getUserBalanceHistory(
        _userId,
        page: state.page,
        pageSize: _pageSize,
        type: state.type.isEmpty ? null : state.type,
      );
      final data = (resp['data'] as Map<String, dynamic>?) ?? resp;
      final pageData = UserBalanceHistoryPageData.fromJson(data);
      state = state.copyWith(
        items: pageData.items,
        total: pageData.total,
        pages: pageData.pages,
        totalRecharged: pageData.totalRecharged,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 切换余额变动历史过滤的记录类型。
  ///
  /// 切换后会自动将页码重置为第 1 页。
  Future<void> filterByType(String type) async {
    state = state.copyWith(type: type, page: 1);
    await load();
  }

  /// 跳转至指定页码。
  Future<void> goToPage(int page) async {
    state = state.copyWith(page: page);
    await load();
  }

  /// 刷新数据。
  Future<void> refresh() => load();
}
