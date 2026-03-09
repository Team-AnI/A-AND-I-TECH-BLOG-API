import 'post_author.dart';
import 'post_status.dart';

/// 게시글 단건 응답 모델입니다.
class PostResponse {
  PostResponse({
    required this.id,
    required this.title,
    this.summary,
    this.contentMarkdown,
    this.thumbnailUrl,
    required this.author,
    required this.collaborators,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  /// 게시글 ID(UUID 문자열)
  final String id;

  /// 게시글 제목
  final String title;

  /// 요약 텍스트
  final String? summary;

  /// Markdown 본문
  final String? contentMarkdown;

  /// 썸네일 URL
  final String? thumbnailUrl;

  /// 작성자 정보
  final PostAuthor author;

  /// 협업자 목록(없으면 빈 배열)
  final List<PostAuthor> collaborators;

  /// 게시 상태 (`Draft`, `Published`, `Deleted`)
  final PostStatus status;

  /// 생성 시각(ISO-8601 date-time)
  final DateTime? createdAt;

  /// 수정 시각(ISO-8601 date-time)
  final DateTime? updatedAt;

  factory PostResponse.fromJson(Map<String, dynamic> json) {
    final rawAuthor = json['author'];
    final rawCollaborators = json['collaborators'];
    final rawStatus = json['status']?.toString() ?? 'Draft';

    return PostResponse(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString(),
      contentMarkdown: json['contentMarkdown']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      author: rawAuthor is Map<String, dynamic>
          ? PostAuthor.fromJson(rawAuthor)
          : PostAuthor(id: ''),
      collaborators: rawCollaborators is List
          ? rawCollaborators
                .whereType<Map<String, dynamic>>()
                .map(PostAuthor.fromJson)
                .toList()
          : const <PostAuthor>[],
      status: postStatusFromApi(rawStatus),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static DateTime? _parseDateTime(Object? rawValue) {
    final stringValue = rawValue?.toString();
    if (stringValue == null || stringValue.isEmpty) {
      return null;
    }
    return DateTime.tryParse(stringValue);
  }
}
