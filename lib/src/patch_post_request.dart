import 'post_author.dart';
import 'post_status.dart';
import 'post_type.dart';

/// 게시글 부분 수정(PATCH) 요청 모델입니다.
///
/// 모든 필드는 선택이며, null 필드는 전송에서 제외됩니다.
class PatchPostRequest {
  PatchPostRequest({
    this.title,
    this.summary,
    this.contentMarkdown,
    this.thumbnailUrl,
    this.author,
    this.collaborators,
    this.type,
    this.status,
    this.scheduledPublishAt,
  });

  /// 제목 (최소 1자, 최대 200자)입니다.
  final String? title;

  /// 요약 (최대 300자)입니다.
  final String? summary;

  /// Markdown 본문입니다.
  final String? contentMarkdown;

  /// 썸네일 URL(직접 지정 시)입니다.
  final String? thumbnailUrl;

  /// 작성자 정보입니다.
  final PostAuthor? author;

  /// 협업자 목록입니다.
  final List<PostAuthor>? collaborators;

  /// 게시글 유형 (`Blog`, `Lecture`)입니다.
  final PostType? type;

  /// 게시 상태 (`Draft`, `Scheduled`, `Published`, `Deleted`)입니다.
  final PostStatus? status;

  /// 예약 게시 시각입니다.
  final DateTime? scheduledPublishAt;

  /// null이 아닌 필드만 포함해 API 요청 JSON으로 직렬화합니다.
  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (contentMarkdown != null) 'contentMarkdown': contentMarkdown,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (author != null) 'author': author!.toJson(),
      if (collaborators != null)
        'collaborators': collaborators!.map((item) => item.toJson()).toList(),
      if (type != null) 'type': type!.toApi(),
      if (status != null) 'status': status!.toApi(),
      if (scheduledPublishAt != null)
        'scheduledPublishAt': scheduledPublishAt!.toUtc().toIso8601String(),
    };
  }
}
