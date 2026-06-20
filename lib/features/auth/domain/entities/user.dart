class User {
  final int id;
  final String email;
  final String role; // admin | user
  final double balance;
  final int concurrency;
  final String status;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.email,
    required this.role,
    required this.balance,
    required this.concurrency,
    required this.status,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) {
    // 全字段设防：/auth/me 返回嵌套结构时，扁平字段可能缺失，
    // 缺省为安全值，避免强转抛 TypeError 导致冷启动校验失败被踢回登录页
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      concurrency: (json['concurrency'] as num?)?.toInt() ?? 1,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
