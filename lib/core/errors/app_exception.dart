class AppException implements Exception {
  final String message;
  final int? statusCode;
  final AppExceptionType type;

  const AppException({required this.message, this.statusCode, required this.type});

  factory AppException.network(String msg) =>
      AppException(message: msg, type: AppExceptionType.network);
  factory AppException.unauthorized() =>
      AppException(message: '登录已过期，请重新登录', statusCode: 401, type: AppExceptionType.unauthorized);
  factory AppException.validation(String msg) =>
      AppException(message: msg, type: AppExceptionType.validation);
  factory AppException.server(String msg, [int? code]) =>
      AppException(message: msg, statusCode: code, type: AppExceptionType.server);
  factory AppException.unknown() =>
      AppException(message: '未知错误，请稍后重试', type: AppExceptionType.unknown);

  @override
  String toString() => 'AppException($type): $message';
}

enum AppExceptionType { network, unauthorized, validation, server, unknown }
