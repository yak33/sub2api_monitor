class ApiKey {
  final int id;
  final String key;
  final String name;
  final String status;
  final double quota;
  final double quotaUsed;
  final int? rateLimit5h;
  final int? rateLimit1d;
  final int? rateLimit7d;
  final int usage5h;
  final int usage1d;
  final int usage7d;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const ApiKey({
    required this.id,
    required this.key,
    required this.name,
    required this.status,
    required this.quota,
    required this.quotaUsed,
    this.rateLimit5h,
    this.rateLimit1d,
    this.rateLimit7d,
    this.usage5h = 0,
    this.usage1d = 0,
    this.usage7d = 0,
    this.expiresAt,
    required this.createdAt,
  });

  double get quotaRemaining => quota - quotaUsed;
  double get quotaUsagePercent => quota > 0 ? (quotaUsed / quota).clamp(0, 1) : 0;
  bool get isActive => status == 'active';
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory ApiKey.fromJson(Map<String, dynamic> json) {
    return ApiKey(
      id: json['id'] as int,
      key: json['key'] as String,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      quota: (json['quota'] as num?)?.toDouble() ?? 0,
      quotaUsed: (json['quota_used'] as num?)?.toDouble() ?? 0,
      rateLimit5h: json['rate_limit_5h'] as int?,
      rateLimit1d: json['rate_limit_1d'] as int?,
      rateLimit7d: json['rate_limit_7d'] as int?,
      usage5h: json['usage_5h'] as int? ?? 0,
      usage1d: json['usage_1d'] as int? ?? 0,
      usage7d: json['usage_7d'] as int? ?? 0,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
