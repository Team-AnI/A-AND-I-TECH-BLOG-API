import 'post_author.dart';

/// 협업자 추가 요청 모델입니다.
class AddCollaboratorRequest {
  AddCollaboratorRequest({this.ownerId, required this.collaborator});

  /// 레거시 호환용 소유자 ID입니다.
  ///
  /// v2 스펙 전송 본문에는 포함되지 않습니다.
  final String? ownerId;

  /// 추가할 협업자 정보입니다. `id`는 필수입니다.
  final PostAuthor collaborator;

  /// API 요청 JSON으로 직렬화합니다.
  Map<String, dynamic> toJson() {
    return {
      'collaborator': collaborator.toJson(),
    };
  }
}
