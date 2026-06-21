import 'package:dio/dio.dart';

import '../../../../shared/errors/app_exception.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_storage.dart';
import '../datasources/remote/api_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final AuthStorage storage;

  AuthRepositoryImpl({required this.apiClient, required this.storage});

  @override
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await apiClient.login(email, password);
      // sub2api 响应格式: {code: 0, message: "success", data: {token, user, refresh_token}}
      final responseData = response['data'] ?? response;
      // sub2api 登录响应字段为 access_token（非 token）
      final token = responseData['access_token'] as String;
      final user = User.fromJson(responseData['user'] as Map<String, dynamic>);

      await storage.saveToken(token);

      // 保存 refresh_token（如果返回了）
      if (responseData['refresh_token'] != null) {
        await storage.saveRefreshToken(responseData['refresh_token'] as String);
      }

      return AuthResult(user: user, token: token);
    } catch (e) {
      throw _translate(e);
    }
  }

  @override
  Future<User> getCurrentUser() async {
    final data = await apiClient.getCurrentUser();
    return User.fromJson(data['data'] ?? data);
  }

  @override
  Future<String?> getStoredToken() async {
    return await storage.getToken();
  }

  @override
  Future<void> logout() async {
    await storage.clearAll();
  }

  /// 将底层异常（主要是 [DioException]）翻译成对用户友好的 [AppException]。
  AppException _translate(Object e) {
    // 已经是 AppException 直接返回（防御性）
    if (e is AppException) return e;

    if (e is DioException) {
      // 优先采用后端返回的业务 message（通常是中文）
      final backendMsg = _backendMessage(e);
      final code = e.response?.statusCode;

      // 网络层错误（连接超时、发送/接收超时、连接失败、证书错误等）
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return AppException('网络连接超时，请检查网络后重试', type: ErrorType.network, statusCode: code);
        case DioExceptionType.connectionError:
          return AppException('无法连接到服务器，请检查网络或服务器地址设置', type: ErrorType.network, statusCode: code);
        case DioExceptionType.badCertificate:
          return AppException('服务器证书校验失败', type: ErrorType.network, statusCode: code);
        case DioExceptionType.cancel:
          return AppException('请求已取消', statusCode: code);
        case DioExceptionType.badResponse:
        case DioExceptionType.unknown:
          break; // 落到下面按状态码分支处理
      }

      // 响应已到达，但状态码非 2xx
      if (code == 401) {
        return AppException(backendMsg ?? '邮箱或密码错误', type: ErrorType.auth, statusCode: code);
      }
      if (code == 403) {
        return AppException(backendMsg ?? '账号无权限登录', type: ErrorType.auth, statusCode: code);
      }
      if (code == 404) {
        return AppException(backendMsg ?? '登录接口不存在，请检查服务器地址', type: ErrorType.server, statusCode: code);
      }
      if (code == 429) {
        return AppException(backendMsg ?? '尝试过于频繁，请稍后再试', type: ErrorType.server, statusCode: code);
      }
      if (code != null && code >= 500) {
        return AppException(backendMsg ?? '服务器异常（$code），请稍后重试', type: ErrorType.server, statusCode: code);
      }
      return AppException(backendMsg ?? '登录失败（$code）', statusCode: code);
    }

    // 其它未知异常（如 JSON 解析失败）
    return const AppException('登录失败，请重试');
  }

  /// 从 Dio 错误响应里提取后端的 message 字段，失败返回 null。
  String? _backendMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map) {
        final m = data['message'];
        if (m is String && m.trim().isNotEmpty) return m.trim();
        // sub2api 部分错误用 error 字段
        final err = data['error'];
        if (err is String && err.trim().isNotEmpty) return err.trim();
      }
    } catch (_) {
      // 忽略解析失败
    }
    return null;
  }
}
