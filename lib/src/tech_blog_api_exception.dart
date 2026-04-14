/// Tech Blog API 호출 실패를 나타내는 예외입니다.
class TechBlogApiException implements Exception {
  /// [message]는 사용자에게 노출 가능한 오류 메시지입니다.
  ///
  /// [statusCode]는 HTTP 상태 코드, [code]는 서버의 도메인 오류 코드입니다.
  TechBlogApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.value,
    this.alert,
  });

  /// 사용자에게 노출 가능한 오류 메시지입니다.
  final String message;

  /// 서버가 응답한 HTTP 상태 코드입니다.
  final int? statusCode;

  /// 서버가 내려주는 비즈니스 오류 코드입니다.
  ///
  /// 예: `BAD_REQUEST`, `FORBIDDEN`, `NOT_FOUND`, `PAYLOAD_TOO_LARGE`
  final String? code;

  /// 서버가 내려주는 오류 value입니다.
  final String? value;

  /// 사용자 안내용 alert 메시지입니다.
  final String? alert;

  @override
  String toString() {
    return 'TechBlogApiException(statusCode: $statusCode, code: $code, value: $value, alert: $alert, message: $message)';
  }
}
