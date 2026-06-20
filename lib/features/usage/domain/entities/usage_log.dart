class UsageLog {
  final int id;
  final String requestId;
  final String model;
  final String? requestedModel;
  final String? upstreamModel;
  final int inputTokens;
  final int outputTokens;
  final int cacheCreationTokens;
  final int cacheReadTokens;
  final double inputCost;
  final double outputCost;
  final double totalCost;
  final bool stream;
  final int durationMs;
  final int? firstTokenMs;
  final String billingType;
  final DateTime createdAt;

  const UsageLog({
    required this.id,
    required this.requestId,
    required this.model,
    this.requestedModel,
    this.upstreamModel,
    required this.inputTokens,
    required this.outputTokens,
    this.cacheCreationTokens = 0,
    this.cacheReadTokens = 0,
    required this.inputCost,
    required this.outputCost,
    required this.totalCost,
    required this.stream,
    required this.durationMs,
    this.firstTokenMs,
    required this.billingType,
    required this.createdAt,
  });

  int get totalTokens => inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens;

  factory UsageLog.fromJson(Map<String, dynamic> json) {
    return UsageLog(
      id: (json['id'] as num?)?.toInt() ?? 0,
      requestId: json['request_id']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      requestedModel: json['requested_model']?.toString(),
      upstreamModel: json['upstream_model']?.toString(),
      inputTokens: (json['input_tokens'] as num?)?.toInt() ?? 0,
      outputTokens: (json['output_tokens'] as num?)?.toInt() ?? 0,
      cacheCreationTokens: (json['cache_creation_tokens'] as num?)?.toInt() ?? 0,
      cacheReadTokens: (json['cache_read_tokens'] as num?)?.toInt() ?? 0,
      inputCost: (json['input_cost'] as num?)?.toDouble() ?? 0,
      outputCost: (json['output_cost'] as num?)?.toDouble() ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      stream: json['stream'] as bool? ?? false,
      durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
      firstTokenMs: (json['first_token_ms'] as num?)?.toInt(),
      billingType: json['billing_type']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
