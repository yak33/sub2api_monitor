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
}
