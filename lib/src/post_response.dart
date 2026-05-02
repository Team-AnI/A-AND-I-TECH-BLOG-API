import 'post_author.dart';
import 'post_status.dart';
import 'post_type.dart';

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
    this.type,
    required this.status,
    this.scheduledPublishAt,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// 게시글 ID(UUID 문자열)입니다.
  final String id;

  /// 게시글 제목입니다.
  final String title;

  /// 요약 텍스트입니다.
  final String? summary;

  /// Markdown 본문입니다.
  final String? contentMarkdown;

  /// 썸네일 URL입니다.
  final String? thumbnailUrl;

  /// 작성자 정보입니다.
  final PostAuthor author;

  /// 협업자 목록입니다.
  final List<PostAuthor> collaborators;

  /// 게시글 유형 (`Blog`, `Lecture`)입니다.
  final PostType? type;

  /// 게시 상태 (`Draft`, `Scheduled`, `Published`, `Deleted`)입니다.
  final PostStatus status;

  /// 예약 게시 시각입니다.
  final DateTime? scheduledPublishAt;

  /// 실제 게시 시각입니다.
  final DateTime? publishedAt;

  /// 생성 시각입니다.
  final DateTime? createdAt;

  /// 수정 시각입니다.
  final DateTime? updatedAt;

  factory PostResponse.fromJson(Map<String, dynamic> json) {
    final rawAuthor = json['author'];
    final rawCollaborators = json['collaborators'];
    final rawType = json['type']?.toString();
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
              .toList(growable: false)
          : const <PostAuthor>[],
      type:
          rawType == null || rawType.isEmpty ? null : postTypeFromApi(rawType),
      status: postStatusFromApi(rawStatus),
      scheduledPublishAt: _parseDateTime(json['scheduledPublishAt']),
      publishedAt: _parseDateTime(json['publishedAt']),
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
