/// 게시글 유형입니다.
enum PostType { blog, lecture }

/// [PostType]을 API 문자열 포맷으로 변환합니다.
extension PostTypeApi on PostType {
  String toApi() {
    return switch (this) {
      PostType.blog => 'Blog',
      PostType.lecture => 'Lecture',
    };
  }
}

/// API 문자열을 [PostType]으로 변환합니다.
PostType postTypeFromApi(String value) {
  return switch (value) {
    'Blog' => PostType.blog,
    'Lecture' => PostType.lecture,
    _ => throw ArgumentError.value(value, 'value', 'Unknown post type'),
  };
}
