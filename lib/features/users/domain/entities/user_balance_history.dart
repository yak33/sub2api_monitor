/// 用户余额变动历史记录（充值记录）实体。
///
/// 对齐 backend/internal/handler/dto/types.go 中的 RedeemCode / AdminRedeemCode DTO。
///
/// @author ZHANGCHAO
/// @date 2026/06/27
class UserBalanceHistoryItem {
  final int id;
  final String code;
  final String type;
  final double value;
  final String status;
  final int? usedBy;
  final DateTime? usedAt;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int? groupId;
  final int validityDays;
  final String notes;

  const UserBalanceHistoryItem({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.status,
    this.usedBy,
    this.usedAt,
    required this.createdAt,
    this.expiresAt,
    this.groupId,
    required this.validityDays,
    required this.notes,
  });

  /// 从 JSON 映射实体，增加容错保护以防止解析崩溃。
  factory UserBalanceHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return UserBalanceHistoryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? '',
      usedBy: (json['used_by'] as num?)?.toInt(),
      usedAt: parseDate(json['used_at']),
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
      expiresAt: parseDate(json['expires_at']),
      groupId: (json['group_id'] as num?)?.toInt(),
      validityDays: (json['validity_days'] as num?)?.toInt() ?? 0,
      notes: json['notes']?.toString() ?? '',
    );
  }
}

/// 用户余额变动历史记录分页结果包装器。
///
/// @author ZHANGCHAO
/// @date 2026/06/27
class UserBalanceHistoryPageData {
  final List<UserBalanceHistoryItem> items;
  final int total;
  final int page;
  final int pageSize;
  final int pages;
  final double totalRecharged;

  const UserBalanceHistoryPageData({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.pages,
    required this.totalRecharged,
  });

  factory UserBalanceHistoryPageData.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(UserBalanceHistoryItem.fromJson)
            .toList() ??
        const <UserBalanceHistoryItem>[];

    return UserBalanceHistoryPageData(
      items: list,
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      pages: (json['pages'] as num?)?.toInt() ?? 1,
      totalRecharged: (json['total_recharged'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
