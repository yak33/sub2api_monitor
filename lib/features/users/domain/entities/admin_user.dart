/// 管理员视角的用户实体。
///
/// 对齐 sub2api 后端 AdminUser DTO（backend/internal/handler/dto/types.go），
/// 列表接口额外返回 [currentConcurrency]（实时并发数）。
/// 全字段设防，缺省安全值，避免后端字段增删导致解析崩溃。
class AdminUser {
  final int id;
  final String email;
  final String username;
  final String role;
  final double balance;
  final int concurrency;
  final String status;
  final int rpmLimit;
  final String notes;
  final double totalRecharged;
  final int? currentConcurrency;
  final DateTime? lastActiveAt;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminUser({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    required this.balance,
    required this.concurrency,
    required this.status,
    required this.rpmLimit,
    required this.notes,
    required this.totalRecharged,
    this.currentConcurrency,
    this.lastActiveAt,
    this.lastUsedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isActive => status == 'active';

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    DateTime? _date(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return AdminUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      concurrency: (json['concurrency'] as num?)?.toInt() ?? 1,
      status: json['status']?.toString() ?? 'active',
      rpmLimit: (json['rpm_limit'] as num?)?.toInt() ?? 0,
      notes: json['notes']?.toString() ?? '',
      totalRecharged: (json['total_recharged'] as num?)?.toDouble() ?? 0,
      currentConcurrency: (json['current_concurrency'] as num?)?.toInt(),
      lastActiveAt: _date(json['last_active_at']),
      lastUsedAt: _date(json['last_used_at']),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }
}

/// 用户列表分页结果。
class AdminUserPage {
  final List<AdminUser> items;
  final int total;
  final int page;
  final int pageSize;
  final int pages;

  const AdminUserPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.pages,
  });

  factory AdminUserPage.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(AdminUser.fromJson)
            .toList() ??
        const <AdminUser>[];
    return AdminUserPage(
      items: list,
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      pages: (json['pages'] as num?)?.toInt() ?? 1,
    );
  }
}
