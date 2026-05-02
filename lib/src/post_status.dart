/// 게시글 상태입니다.
enum PostStatus { draft, scheduled, published, deleted }

/// [PostStatus]를 API 문자열 포맷으로 변환합니다.
extension PostStatusApi on PostStatus {
  String toApi() {
    return switch (this) {
      PostStatus.draft => 'Draft',
      PostStatus.scheduled => 'Scheduled',
      PostStatus.published => 'Published',
      PostStatus.deleted => 'Deleted',
    };
  }
}

/// API 문자열을 [PostStatus]로 변환합니다.
PostStatus postStatusFromApi(String value) {
  return switch (value) {
    'Draft' => PostStatus.draft,
    'Scheduled' => PostStatus.scheduled,
    'Published' => PostStatus.published,
    'Deleted' => PostStatus.deleted,
    _ => throw ArgumentError.value(value, 'value', 'Unknown post status'),
  };
}
