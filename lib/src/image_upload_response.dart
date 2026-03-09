/// 이미지 업로드 성공 응답 모델입니다.
class ImageUploadResponse {
  ImageUploadResponse({
    required this.url,
    required this.key,
    this.contentType,
    this.size,
  });

  /// 업로드된 이미지의 공개 URL
  final String url;

  /// 스토리지 키(재사용/삭제 API 연동 시 식별자)
  final String key;

  /// 콘텐츠 타입(예: `image/png`)
  final String? contentType;

  /// 파일 크기(Byte)
  final int? size;

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return ImageUploadResponse(
      url: json['url']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      contentType: json['contentType']?.toString(),
      size: _toInt(json['size']),
    );
  }

  static int? _toInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }
}
