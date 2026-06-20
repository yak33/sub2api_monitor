import 'dart:async';

import 'package:dio/dio.dart';

import '../local/auth_storage.dart';

/// 认证拦截器：注入 JWT + 401 自动刷新。
///
/// 刷新逻辑串行化：当多个请求并发 401 时，仅首个请求触发 refresh，
/// 其余请求复用同一刷新结果，避免 refresh_token 被并发消耗导致失效。
class AuthInterceptor extends Interceptor {
  final AuthStorage storage;
  final Dio dio;

  /// 正在进行的刷新 Future；非空时新的 401 复用它。
  Future<String?>? _refreshingFuture;

  AuthInterceptor({required this.storage, required this.dio});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // refresh 请求本身不注入旧 token，避免循环 401
    if (options.path != '/api/v1/auth/refresh') {
      final token = await storage.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final is401 = err.response?.statusCode == 401;
    // refresh 请求自身的 401 不再尝试刷新，直接走错误流程
    final isRefreshCall = err.requestOptions.path == '/api/v1/auth/refresh';

    if (is401 && !isRefreshCall) {
      try {
        final newToken = await _refreshTokenOnce();
        if (newToken != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await dio.fetch(err.requestOptions);
          handler.resolve(retryResponse);
          return;
        }
      } catch (_) {
        // 刷新或重试失败，继续走错误流程
      }
    }
    handler.next(err);
  }

  /// 串行化刷新：首个 401 触发刷新，其余并发 401 复用同一 Future。
  Future<String?> _refreshTokenOnce() {
    if (_refreshingFuture != null) return _refreshingFuture!;
    _refreshingFuture = _doRefresh();
    return _refreshingFuture!.whenComplete(() => _refreshingFuture = null);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null) return null;
    try {
      final response = await dio.post(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      // sub2api 响应格式: {code: 0, message: "success", data: {access_token, refresh_token}}
      final responseData = response.data['data'] ?? response.data;
      final newToken = responseData['access_token'] as String?;
      if (newToken == null) return null;
      await storage.saveToken(newToken);
      if (responseData['refresh_token'] != null) {
        await storage.saveRefreshToken(responseData['refresh_token'] as String);
      }
      return newToken;
    } catch (_) {
      // 刷新失败，清除登录态
      await storage.clearAll();
      return null;
    }
  }
}
