import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/datasources/local/auth_storage.dart';
import '../../features/auth/data/datasources/remote/api_client.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import 'app_providers.dart'; // 统一使用 BaseUrlNotifier

// ── Storage ──
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage(ref.watch(secureStorageProvider));
});

// ── API Client ──
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(authStorageProvider);
  final baseUrl = ref.watch(baseUrlProvider); // 现在引用 BaseUrlNotifier 版本
  return ApiClient(
    baseUrl: baseUrl,
    storage: storage,
  );
});

// ── Repository ──
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    storage: ref.watch(authStorageProvider),
  );
});

// ── Auth State ──
class AuthState {
  final User? user;
  final String? token;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.token,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    String? token,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.watch(authRepositoryProvider);
    final token = await repo.getStoredToken();
    if (token != null) {
      try {
        final user = await repo.getCurrentUser();
        return AuthState(
          user: user,
          token: token,
          isAuthenticated: true,
        );
      } catch (_) {
        // Token 过期，清除
        await repo.logout();
      }
    }
    return const AuthState();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.login(email, password);
      state = AsyncData(AuthState(
        user: result.user,
        token: result.token,
        isAuthenticated: true,
      ));
    } catch (e) {
      // 失败时保持干净的“未登录”初始状态（不把 error 写进全局 state）。
      // 这样 router 的登录态判断不会因 error 字段抖动，
      // 错误信息只通过 rethrow 交给 LoginPage 局部 _errorText 显示。
      state = const AsyncData(AuthState());
      rethrow;
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncData(AuthState());
  }
}
