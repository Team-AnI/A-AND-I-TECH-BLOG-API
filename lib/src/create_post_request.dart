import 'post_author.dart';
import 'post_status.dart';

/// 게시글 생성 요청 모델입니다.
///
/// OpenAPI 기준 필수 필드는 [title], [author]입니다.
class CreatePostRequest {
  CreatePostRequest({
    required this.title,
    required this.author,
    this.summary,
    this.contentMarkdown,
    this.thumbnailUrl,
    this.collaborators,
    this.status,
  });

  /// 제목 (필수, 최대 200자)
  final String title;

  /// 작성자 정보 (필수)
  final PostAuthor author;

  /// 요약 (선택, 최대 300자)
  final String? summary;

  /// Markdown 본문
  final String? contentMarkdown;

  /// 썸네일 URL(직접 지정 시)
  final String? thumbnailUrl;

  /// 협업자 목록
  final List<PostAuthor>? collaborators;

  /// 게시 상태 (`Draft`, `Published`, `Deleted`)
  final PostStatus? status;

  /// null이 아닌 필드만 포함해 API 요청 JSON으로 직렬화합니다.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (summary != null) 'summary': summary,
      if (contentMarkdown != null) 'contentMarkdown': contentMarkdown,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      'author': author.toJson(),
      if (collaborators != null)
        'collaborators': collaborators!.map((item) => item.toJson()).toList(),
      if (status != null) 'status': status!.toApi(),
    };
  }
}
