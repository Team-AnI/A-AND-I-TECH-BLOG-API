import 'post_author.dart';

/// 협업자 추가 요청 모델입니다.
class AddCollaboratorRequest {
  AddCollaboratorRequest({this.ownerId, required this.collaborator});

  /// 게시글 소유자 ID입니다.
  ///
  /// 일반 사용자 흐름에서는 생략 가능하며, 소유자를 명시해야 하는
  /// 어드민/대리 작업 시나리오에서 함께 전송할 수 있습니다.
  final String? ownerId;

  /// 추가할 협업자 정보입니다. `id`는 필수입니다.
  final PostAuthor collaborator;

  /// API 요청 JSON으로 직렬화합니다.
  Map<String, dynamic> toJson() {
    return {
      if (ownerId != null) 'ownerId': ownerId,
      'collaborator': collaborator.toJson(),
    };
  }
}
