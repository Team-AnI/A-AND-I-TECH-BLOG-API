# Blog Service API v2 요약

이 문서는 2026-05-01 기준 제공된 OpenAPI 3.1 스펙을 바탕으로 정리한 내부 메모입니다.

## 공통 규칙

- Base URL: `https://api.aandiclub.com`
- 인증 헤더: `Authenticate: Bearer {accessToken}`
- 추가 헤더
  - `deviceOS`: 필수
  - `timestamp`: 필수, ISO-8601 instant
  - `salt`: 선택
- 성공 응답 래퍼

```json
{
  "success": true,
  "data": { ... },
  "error": null,
  "timestamp": "2026-04-09T12:00:00Z"
}
```

## 게시글 쓰기 API

- `POST /v2/posts` : 게시글 생성
- `PATCH /v2/posts/{postId}` : 게시글 수정
- `DELETE /v2/posts/{postId}` : 게시글 삭제
- `POST /v2/posts/{postId}/collaborators` : 협업자 추가
- `POST /v2/posts/images` : 이미지 업로드

## 게시글 조회 API

### 범용 조회

- `GET /v2/posts` : 전체 게시글 목록 조회, `deprecated`
- `GET /v2/posts/{postId}` : 게시글 상세 조회, `deprecated`
- `GET /v2/posts/me` : 내 게시글 목록 조회, `deprecated`
- `GET /v2/posts/drafts` : 초안 목록 조회, `deprecated`
- `GET /v2/posts/drafts/me` : 내 초안 목록 조회, `deprecated`
- `GET /v2/posts/scheduled/me` : 내 예약 게시글 목록 조회, `deprecated`

### Blog 전용 조회

- `GET /v2/blogs`
- `GET /v2/blogs/{postId}`
- `GET /v2/blogs/me`
- `GET /v2/blogs/drafts`
- `GET /v2/blogs/drafts/me`
- `GET /v2/blogs/scheduled/me`

### Lecture 전용 조회

- `GET /v2/lectures`
- `GET /v2/lectures/{postId}`
- `GET /v2/lectures/me`
- `GET /v2/lectures/drafts`
- `GET /v2/lectures/drafts/me`
- `GET /v2/lectures/scheduled/me`

## 주요 스키마 변경 포인트

### PostStatus

- `Draft`
- `Scheduled`
- `Published`
- `Deleted`

### V2PostResponse

주요 필드:

- `id`
- `title`
- `summary`
- `contentMarkdown`
- `thumbnailUrl`
- `author`
- `collaborators`
- `type`: `Blog | Lecture`
- `status`: `Draft | Scheduled | Published | Deleted`
- `scheduledPublishAt`
- `publishedAt`
- `createdAt`
- `updatedAt`

### CreatePostRequest / PatchPostRequest

주요 필드:

- `title`
- `summary`
- `contentMarkdown`
- `thumbnailUrl`
- `author`
- `collaborators`
- `type`
- `status`
- `scheduledPublishAt`

## 구현 메모

- 가능한 경우 `/v2/blogs/**`, `/v2/lectures/**` 우선 사용
- 타입을 모를 때만 범용 `/v2/posts/**` fallback 사용
- 협업자 추가 요청 본문은 `collaborator`만 전송

## 패키지 마이그레이션 메모

- 패키지의 범용 조회 메서드(`listPosts*`, `getPost*`, `listMyPosts*`, `listDrafts*`, `listMyDrafts*`)는 deprecated 처리한다.
- 클라이언트 코드는 `blogs`/`lectures` 전용 메서드로 마이그레이션한다.
