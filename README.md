# aandi_tech_blog

A&I Tech Blog API 클라이언트 패키지입니다.  
게시글 조회/생성/수정/삭제, 협업자 추가, 이미지 업로드 기능을 제공합니다.

## 설치

### 1) 워크스페이스(로컬 경로)에서 사용하는 경우

`pubspec.yaml`에 path 의존성을 추가합니다.

```yaml
dependencies:
  aandi_tech_blog:
    path: packages/tech_blog
```

### 2) 외부 프로젝트에서 Git 의존성으로 사용하는 경우

```yaml
dependencies:
  aandi_tech_blog:
    git:
      url: https://github.com/<org>/<repo>.git
      path: packages/tech_blog
      ref: main
```

## 개요

- 패키지명: `aandi_tech_blog`
- 런타임: Dart `^3.10.4`
- 주요 의존성
  - `dio`: HTTP 통신

공개 진입점:

```dart
import 'package:aandi_tech_blog/aandi_tech_blog.dart';
```

상세 OpenAPI 분석 문서는 [api_docs.md](./api_docs.md)를 참고하세요.

## 제공 기능 및 엔드포인트

`TechBlogApiClient`가 아래 기능을 제공합니다.

- `listBlogs`: 블로그 목록 조회 (`GET /v2/blogs`)
- `listLectures`: 강의자료 목록 조회 (`GET /v2/lectures`)
- `getBlog`: 블로그 상세 조회 (`GET /v2/blogs/{postId}`)
- `getLecture`: 강의자료 상세 조회 (`GET /v2/lectures/{postId}`)
- `listMyBlogs`, `listMyLectures`: 내 게시글 목록 조회
- `listMyBlogDrafts`, `listMyLectureDrafts`: 내 초안 목록 조회
- `createPost`: 게시글 생성 (`POST /v1/posts`)
- `patchPost`: 게시글 부분 수정 (`PATCH /v1/posts/{postId}`)
- `deletePost`: 게시글 삭제 (`DELETE /v1/posts/{postId}`)
- `addCollaborator`: 협업자 추가 (`POST /v1/posts/{postId}/collaborators`)
- `uploadImage`: 이미지 업로드 (`POST /v1/posts/images`)

인증 관련 참고:

- 인증이 필요한 메서드(`listMyBlogs`, `listMyLectures`, `listMyBlogDrafts`, `listMyLectureDrafts`, `patchPost`, `addCollaborator`)는 `accessToken` 파라미터가 필수입니다.
- `createPost`, `deletePost`는 시그니처상 `accessToken`이 선택값입니다. 실제 서버 정책에 따라 토큰이 필요할 수 있습니다.

## 빠른 시작

```dart
import 'package:aandi_tech_blog/aandi_tech_blog.dart';
import 'package:dio/dio.dart';

// accessToken은 로그인/인증 절차에서 획득한 JWT를 사용합니다.
// 예: "eyJhbGciOi..."
final accessToken = '<YOUR_ACCESS_TOKEN>';

final client = TechBlogApiClient(
  baseUrl: 'https://api.example.com', // trailing slash 없이 권장
);

// 1) 게시글 목록 조회
final PagedPostResponse posts = await client.listBlogs(
  page: 0,
  size: 20,
  status: PostStatus.published,
);

// 2) 게시글 상세 조회
final PostResponse post = await client.getBlog(
  postId: '9f35dd42-ff17-4e47-8f66-fbc6fce13b8a',
);

// 3) 게시글 생성 (multipart: post + optional thumbnail)
final PostResponse created = await client.createPost(
  accessToken: accessToken,
  post: CreatePostRequest(
    title: 'New Post',
    author: PostAuthor(id: 'owner-1', nickname: 'Owner'),
    summary: '요약',
    contentMarkdown: '# Hello',
    status: PostStatus.draft,
  ),
  thumbnail: await MultipartFile.fromFile('/tmp/thumb.png'),
);

// 4) 게시글 수정 (JSON PATCH)
final PostResponse patched = await client.patchPost(
  postId: created.id,
  accessToken: accessToken,
  post: PatchPostRequest(
    title: 'Updated title',
    status: PostStatus.published,
  ),
);

// 5) 협업자 추가
final PostResponse withCollaborator = await client.addCollaborator(
  postId: patched.id,
  accessToken: accessToken,
  request: AddCollaboratorRequest(
    ownerId: 'owner-1',
    collaborator: PostAuthor(id: 'col-1', nickname: 'Col'),
  ),
);

// 6) 이미지 업로드
// 모바일 환경에서는 image_picker 등으로 얻은 image.path를 사용하세요.
final ImageUploadResponse uploaded = await client.uploadImage(
  file: await MultipartFile.fromFile('/tmp/body-image.png'),
);

// 7) 게시글 삭제
final bool deleted = await client.deletePost(
  postId: withCollaborator.id,
  accessToken: accessToken,
);
```

## 고급 설정 (커스텀 Dio 주입)

실무에서는 로깅, 공통 헤더, 타임아웃, 재시도 정책을 위해 `Dio`를 주입해서 쓰는 것을 권장합니다.

```dart
import 'package:aandi_tech_blog/aandi_tech_blog.dart';
import 'package:dio/dio.dart';

final dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
  ),
)
  ..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // 필요 시 공통 헤더/로깅 처리
        options.headers['X-Client'] = 'admin-web';
        handler.next(options);
      },
    ),
  );

final client = TechBlogApiClient(
  baseUrl: 'https://api.example.com',
  dio: dio,
);
```

참고:

- 이 패키지는 메서드 파라미터로 전달된 `accessToken`이 있으면 해당 요청에 Authorization 헤더를 직접 설정합니다.
- 따라서 인증 토큰은 `accessToken` 파라미터 전달 방식과 `Dio` interceptor 방식 중 하나로 정책을 통일하는 것을 권장합니다.
- 권장 기준
  - 간단한 테스트/스크립트/PoC: 메서드 파라미터(`accessToken`) 방식
  - 실제 앱/웹 프로덕션: `Dio` interceptor 기반 전역 인증 처리 방식

## API 계약(응답 형식)

이 패키지는 다음 규칙으로 응답을 처리합니다.

- 2xx 응답은 메서드별 DTO로 파싱
  - 예: `PostResponse`, `PagedPostResponse`, `ImageUploadResponse`
- non-2xx 응답은 `error.message`, `error.code`가 있으면 추출하여 예외화
- `deletePost`는 `data`에서 bool 값을 찾아 반환
  - bool 단일값 또는 `Map<String, bool>` 형태를 허용

Multipart 요청 규칙:

- `createPost`, `patchPost`에서 multipart 모드를 사용할 때, 이 패키지가 `post` 객체를 JSON 문자열로 직렬화해 `post` 필드로 전송합니다.
- 즉, 호출자는 `CreatePostRequest`/`PatchPostRequest` 객체만 넘기면 되며, `jsonEncode`를 직접 호출할 필요가 없습니다.

이미지 업로드 주의사항:

- `uploadImage`는 서버 정책 위반 시 `413`(Payload Too Large), `415`(Unsupported Media Type)를 반환할 수 있습니다.
- 허용 확장자/MIME 타입/최대 용량은 서버 환경 설정에 따르므로, 운영 환경 기준값을 백엔드 스펙과 함께 확정해 사용하는 것을 권장합니다.

`createPost`(multipart) 실패 처리 참고:

- 이 클라이언트는 `createPost` 호출에서 non-2xx(예: `413`, `415`) 응답을 받으면 요청 전체를 실패(`TechBlogApiException`)로 처리합니다.
- 백엔드 트랜잭션 정책(텍스트/이미지 원자성)은 서버 구현에 따라 달라질 수 있으므로, 운영 전 백엔드와 "실패 시 글 생성 여부"를 명시적으로 합의하는 것을 권장합니다.

## 주요 타입

### 모델 요약

| 타입 | 용도 | 핵심 필드(타입) | 비고 |
|---|---|---|---|
| `PostStatus` | 게시글 상태 enum | `draft/scheduled/published/deleted` | API 문자열: `Draft`, `Scheduled`, `Published`, `Deleted` |
| `PostAuthor` | 작성자/협업자 | `id(String)`, `nickname(String?)`, `profileImageUrl(String?)` | `id` 필수 |
| `PostResponse` | 게시글 단건 응답 | `id(String)`, `title(String)`, `status(PostStatus)`, `author(PostAuthor)`, `collaborators(List<PostAuthor>)`, `createdAt(DateTime?)` | 상세 조회/생성/수정/협업자 응답에 사용 |
| `PagedPostResponse` | 목록 페이징 응답 | `items(List<PostResponse>)`, `page(int)`, `size(int)`, `totalElements(int)`, `totalPages(int)` | 목록 계열 API 공통 |
| `CreatePostRequest` | 게시글 생성 요청 | 필수: `title(String)`, `author(PostAuthor)` / 선택: `summary(String?)`, `contentMarkdown(String?)`, `thumbnailUrl(String?)`, `collaborators(List<PostAuthor>?)`, `status(PostStatus?)` | 생성 요청 payload |
| `PatchPostRequest` | 게시글 부분 수정 요청 | `title(String?)`, `summary(String?)`, `contentMarkdown(String?)`, `thumbnailUrl(String?)`, `author(PostAuthor?)`, `collaborators(List<PostAuthor>?)`, `status(PostStatus?)` | null 필드는 전송 제외 |
| `AddCollaboratorRequest` | 협업자 추가 요청 | `collaborator(PostAuthor)`, `ownerId(String?)` | `ownerId`는 옵션 |
| `ImageUploadResponse` | 이미지 업로드 응답 | `url(String)`, `key(String)`, `contentType(String?)`, `size(int?)` | `url`은 공개 접근 URL |

## 페이징 팁

`listPosts`/`listMyPosts`/`listDrafts`/`listMyDrafts`는 모두 같은 페이징 구조를 반환합니다.

```dart
var page = 0;
const size = 20;

while (true) {
  final result = await client.listPosts(page: page, size: size);
  // result.items 처리

  if (page + 1 >= result.totalPages) {
    break;
  }
  page += 1;
}
```

## 예외 처리

요청 실패/응답 파싱 실패는 `TechBlogApiException`으로 전달됩니다.

```dart
try {
  await client.listMyPosts(accessToken: accessToken);
} on TechBlogApiException catch (e) {
  // e.message: 사용자 노출 가능한 메시지
  // e.statusCode: HTTP 상태 코드
  // e.code: 서버 도메인 에러 코드 (없으면 null)
}
```

대표적인 `e.code` 예시(서버 구현에 따라 달라질 수 있음):

- `BAD_REQUEST`
- `UNAUTHORIZED`
- `FORBIDDEN`
- `NOT_FOUND`
- `PAYLOAD_TOO_LARGE`
- `UNSUPPORTED_MEDIA_TYPE`

## 테스트

패키지 루트에서:

```bash
flutter test test/tech_blog_api_client_test.dart
```

워크스페이스 루트에서:

```bash
flutter test packages/tech_blog/test/tech_blog_api_client_test.dart
```

## 개발 메모

- `TechBlogApiClient` 생성자에 `Dio`를 주입할 수 있어 테스트/인터셉터 구성에 유리합니다.
- `createPost`, `patchPost`의 multipart 모드에서는 내부적으로 `post`를 JSON 문자열로 직렬화해 `post` 필드에 넣습니다.
- 인증 토큰은 메서드 파라미터(`accessToken`) 또는 `Dio` interceptor 방식 중 하나로 일관되게 운영하는 것을 권장합니다.
- 서버 에러 payload에 `error.message`, `error.code`가 있으면 `TechBlogApiException`으로 변환해 전달합니다.


## Deprecated 안내

- 범용 조회 메서드(`listPosts`, `getPost`, `listMyPosts`, `listDrafts`, `listMyDrafts` 및 `*V2` 변형)는 deprecated 처리되었습니다.
- 조회 시에는 타입별 전용 메서드(`listBlogs`, `listLectures`, `getBlog`, `getLecture` 등)를 사용하세요.
