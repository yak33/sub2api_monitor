import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../entities/usage_log.dart';

final usageLogsProvider = AsyncNotifierProvider<UsageLogsNotifier, UsageLogsState>(() {
  return UsageLogsNotifier();
});

class UsageLogsState {
  final List<UsageLog> logs;
  final int page;
  final int totalPages;
  final bool hasMore;

  const UsageLogsState({
    this.logs = const [],
    this.page = 1,
    this.totalPages = 1,
    this.hasMore = false,
  });

  UsageLogsState copyWith({
    List<UsageLog>? logs,
    int? page,
    int? totalPages,
    bool? hasMore,
  }) {
    return UsageLogsState(
      logs: logs ?? this.logs,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class UsageLogsNotifier extends AsyncNotifier<UsageLogsState> {
  bool _isLoadingMore = false;

  @override
  Future<UsageLogsState> build() async {
    return _fetchLogs(1);
  }

  Future<UsageLogsState> _fetchLogs(int page) async {
    final apiClient = ref.read(apiClientProvider);
    final data = await apiClient.getUsageLogs(page: page, pageSize: 20);
    final items = (data['data']?['items'] as List?)
            ?.map((e) => UsageLog.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final total = data['data']?['total'] as int? ?? 1;

    return UsageLogsState(
      logs: items,
      page: page,
      totalPages: (total / 20).ceil(),
      hasMore: page < (total / 20).ceil(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchLogs(1));
  }

  Future<void> loadMore() async {
    if (_isLoadingMore) return; // 防止 itemBuilder 重复触发并发请求
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;

    _isLoadingMore = true;
    final nextPage = current.page + 1;
    try {
      final newState = await _fetchLogs(nextPage);
      state = AsyncData(UsageLogsState(
        logs: [...current.logs, ...newState.logs],
        page: nextPage,
        totalPages: newState.totalPages,
        hasMore: newState.hasMore,
      ));
    } catch (e) {
      // 保持当前状态
    } finally {
      _isLoadingMore = false;
    }
  }
}
