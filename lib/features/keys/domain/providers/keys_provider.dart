import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../entities/api_key.dart';

final apiKeysProvider = AsyncNotifierProvider<ApiKeysNotifier, List<ApiKey>>(() {
  return ApiKeysNotifier();
});

class ApiKeysNotifier extends AsyncNotifier<List<ApiKey>> {
  @override
  Future<List<ApiKey>> build() async {
    return _fetchKeys();
  }

  Future<List<ApiKey>> _fetchKeys() async {
    final apiClient = ref.read(apiClientProvider);
    final data = await apiClient.getApiKeys();
    final items = (data['data']?['items'] as List?)
            ?.map((e) => ApiKey.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchKeys());
  }

  Future<void> createKey(Map<String, dynamic> data) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.createApiKey(data);
    await refresh();
  }

  Future<void> deleteKey(int id) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.deleteApiKey(id);
    await refresh();
  }
}
