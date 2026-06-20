import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/domain/providers/dashboard_provider.dart';
import '../../features/usage/domain/providers/usage_provider.dart';
import '../../features/keys/domain/providers/keys_provider.dart';

/// 全局刷新 Provider
final globalRefreshProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await Future.wait([
      ref.read(dashboardProvider.notifier).refresh(),
      ref.read(usageLogsProvider.notifier).refresh(),
      ref.read(apiKeysProvider.notifier).refresh(),
    ]);
  };
});
