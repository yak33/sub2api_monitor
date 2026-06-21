/// 应用统一异常类型，便于 UI 按类型显示不同样式/行为。
enum ErrorType {
  /// 网络不通、连接超时、DNS 解析失败等
  network,

  /// 凭据错误（401）、无权限（403）等业务鉴权问题
  auth,

  /// 服务端异常（5xx）
  server,

  /// 其它未分类错误
  unknown,
}

/// 应用统一异常。
///
/// [message] 面向用户的友好文案；
/// [type] 用于 UI 区分网络/鉴权/服务端等场景；
/// [statusCode] 保留原始 HTTP 状态码（可能为空）。
class AppException implements Exception {
  final String message;
  final ErrorType type;
  final int? statusCode;

  const AppException(
    this.message, {
    this.type = ErrorType.unknown,
    this.statusCode,
  });

  @override
  String toString() => message;
}
