/// 게시글 작성자/협업자 정보를 표현하는 모델입니다.
class PostAuthor {
  PostAuthor({required this.id, this.nickname, this.profileImageUrl});

  /// 사용자 식별자입니다.
  ///
  /// OpenAPI 제약: 공백만으로 구성될 수 없고, 최대 100자입니다.
  final String id;

  /// 표시용 닉네임입니다. OpenAPI 제약: 최대 50자.
  final String? nickname;

  /// 프로필 이미지 URL입니다.
  final String? profileImageUrl;

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id']?.toString() ?? '',
      nickname: json['nickname']?.toString(),
      profileImageUrl: json['profileImageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (nickname != null) 'nickname': nickname,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    };
  }
}
