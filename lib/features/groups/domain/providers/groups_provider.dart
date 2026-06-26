import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../entities/group.dart';

const _sentinel = Object();

/// 分组列表页面状态。
///
/// @author ZHANGCHAO
/// @date 2026/06/27
class GroupsListState {
  final List<AdminGroup> items;
  final int total;
  final int page;
  final int pages;
  final bool isLoading;
  final String? error;
  final String search;
  final String? filterPlatform;
  final String? filterStatus;

  const GroupsListState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pages = 1,
    this.isLoading = false,
    this.error,
    this.search = '',
    this.filterPlatform,
    this.filterStatus,
  });

  GroupsListState copyWith({
    List<AdminGroup>? items,
    int? total,
    int? page,
    int? pages,
    bool? isLoading,
    String? error,
    String? search,
    Object? filterPlatform = _sentinel,
    Object? filterStatus = _sentinel,
  }) =>
      GroupsListState(
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        pages: pages ?? this.pages,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        search: search ?? this.search,
        filterPlatform: identical(filterPlatform, _sentinel)
            ? this.filterPlatform
            : (filterPlatform as String?),
        filterStatus: identical(filterStatus, _sentinel)
            ? this.filterStatus
            : (filterStatus as String?),
      );
}

/// 管理员级分组列表状态提供者。
///
/// @author ZHANGCHAO
/// @date 2026/06/27
final groupsListProvider =
    StateNotifierProvider<GroupsListNotifier, GroupsListState>((ref) {
  return GroupsListNotifier(ref);
});

class GroupsListNotifier extends StateNotifier<GroupsListState> {
  final Ref _ref;
  static const _pageSize = 20;

  GroupsListNotifier(this._ref) : super(const GroupsListState()) {
    _load();
  }

  /// 加载当前筛选和页码条件下的分组列表数据。
  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(apiClientProvider);
      final resp = await api.getAdminGroups(
        page: state.page,
        pageSize: _pageSize,
        search: state.search.isEmpty ? null : state.search,
        platform: state.filterPlatform,
        status: state.filterStatus,
      );
      final data = (resp['data'] as Map<String, dynamic>?) ?? resp;
      final items = (data['items'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(AdminGroup.fromJson)
              .toList() ??
          const <AdminGroup>[];
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

  /// 搜索过滤（重置至第 1 页）。
  Future<void> search(String keyword) async {
    state = state.copyWith(search: keyword, page: 1);
    await _load();
  }

  /// 平台过滤（重置至第 1 页，支持通过传递 null 清除过滤）。
  Future<void> filterByPlatform(String? platform) async {
    state = state.copyWith(filterPlatform: platform, page: 1);
    await _load();
  }

  /// 状态过滤（重置至第 1 页，支持通过传递 null 清除过滤）。
  Future<void> filterByStatus(String? status) async {
    state = state.copyWith(filterStatus: status, page: 1);
    await _load();
  }

  /// 翻页跳转。
  Future<void> goToPage(int page) async {
    state = state.copyWith(page: page);
    await _load();
  }

  /// 刷新数据。
  Future<void> refresh() => _load();

  // ── 写入操作 (CRUD) ──

  /// 创建新分组。
  Future<void> createGroup(Map<String, dynamic> data) async {
    final api = _ref.read(apiClientProvider);
    await api.createAdminGroup(data);
    await _load();
  }

  /// 更新指定分组。
  Future<void> updateGroup(int id, Map<String, dynamic> data) async {
    final api = _ref.read(apiClientProvider);
    await api.updateAdminGroup(id, data);
    await _load();
  }

  /// 删除指定分组。
  Future<void> deleteGroup(int id) async {
    final api = _ref.read(apiClientProvider);
    await api.deleteAdminGroup(id);
    await _load();
  }

  // ── 专属配置写操作 ──

  /// 同步/覆盖指定分组下的专属计费倍数配置。
  Future<void> saveRateMultipliers(int id, List<Map<String, dynamic>> entries) async {
    final api = _ref.read(apiClientProvider);
    if (entries.isEmpty) {
      await api.clearGroupRateMultipliers(id);
    } else {
      await api.updateGroupRateMultipliers(id, entries);
    }
    await _load();
  }

  /// 同步/覆盖指定分组下的专属 RPM 配置。
  Future<void> saveRpmOverrides(int id, List<Map<String, dynamic>> entries) async {
    final api = _ref.read(apiClientProvider);
    if (entries.isEmpty) {
      await api.clearGroupRpmOverrides(id);
    } else {
      await api.updateGroupRpmOverrides(id, entries);
    }
    await _load();
  }
}
