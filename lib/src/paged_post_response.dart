import 'post_response.dart';

/// 게시글 페이징 응답 모델입니다.
class PagedPostResponse {
  PagedPostResponse({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  /// 현재 페이지의 게시글 목록
  final List<PostResponse> items;

  /// 현재 페이지 번호(0-based)
  final int page;

  /// 페이지 크기
  final int size;

  /// 전체 요소 수
  final int totalElements;

  /// 전체 페이지 수
  final int totalPages;

  factory PagedPostResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Invalid paged post response');
    }

    return PagedPostResponse(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(PostResponse.fromJson)
          .toList(),
      page: _toInt(json['page']),
      size: _toInt(json['size']),
      totalElements: _toInt(json['totalElements']),
      totalPages: _toInt(json['totalPages']),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
