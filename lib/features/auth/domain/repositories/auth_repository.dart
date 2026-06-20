import '../../domain/entities/user.dart';

class AuthResult {
  final User user;
  final String token;

  const AuthResult({required this.user, required this.token});
}

abstract class AuthRepository {
  Future<AuthResult> login(String email, String password);
  Future<User> getCurrentUser();
  Future<String?> getStoredToken();
  Future<void> logout();
}
