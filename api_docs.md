# Blog Service API 분석 문서

## 1) 문서 개요
- OpenAPI 버전: `3.1.0`
- API 제목: `Blog Service API`
- 서버: `https://api.aandiclub.com`
- 버전: `v1`
- 태그: `Posts`, `Images`

이 문서는 제공된 OpenAPI 스펙을 기준으로, 엔드포인트 역할/인증 정책/요청-응답 구조/클라이언트 구현 시 주의사항을 정리한 분석 문서다.

## 2) 전체 API 구조 요약
- 리소스 중심: 게시글(`posts`) + 이미지 업로드(`posts/images`)
- 게시글 상태 모델: `Draft | Published | Deleted`
- 협업 모델: 작성자(`author`) + 공동 작성자(`collaborators`) 배열
- 페이징 목록 API 다수 제공: `page`, `size`, `status` 기반
- 생성/수정에서 `multipart/form-data`를 사용해 썸네일 파일 동시 업로드 가능

## 3) 엔드포인트 맵

| Method | Path | 설명 | 인증 |
|---|---|---|---|
| `GET` | `/v1/posts` | 게시글 목록 조회 | 없음(스펙상 Public) |
| `POST` | `/v1/posts` | 게시글 생성(멀티파트) | 명시 없음 |
| `GET` | `/v1/posts/{postId}` | 게시글 상세 조회 | 없음 |
| `PATCH` | `/v1/posts/{postId}` | 게시글 부분 수정(JSON/멀티파트) | `bearerAuth` |
| `DELETE` | `/v1/posts/{postId}` | 게시글 삭제 | 명시 없음 |
| `GET` | `/v1/posts/me` | 내 게시글 목록(소유자/협업자) | `bearerAuth` |
| `GET` | `/v1/posts/drafts` | 초안 목록 조회 | 없음 |
| `GET` | `/v1/posts/drafts/me` | 내 초안 목록 | `bearerAuth` |
| `POST` | `/v1/posts/{postId}/collaborators` | 협업자 추가(owner only) | `bearerAuth` |
| `POST` | `/v1/posts/images` | 이미지 업로드 | 명시 없음 |

## 4) 인증/인가 분석

### 확인된 사실
- 전역 보안 스키마는 `bearerAuth`(JWT Bearer)로 정의됨.
- 일부 엔드포인트(`PATCH /posts/{id}`, `/posts/me`, `/posts/drafts/me`, `POST /posts/{id}/collaborators`)에만 `security`가 명시됨.
- 같은 엔드포인트들에 `Authorization` 헤더 파라미터가 별도로 중복 선언된 경우가 있음.

### 해석(추정)
- 실제 서버는 더 많은 엔드포인트에서 인증을 요구할 수 있으나, 스펙 문서에는 일관되게 반영되지 않았을 가능성이 높다.

### 클라이언트 권장
- 토큰 보유 시 기본적으로 `Authorization: Bearer <token>`를 항상 붙이고, `401/403` 응답 기준으로 UI 분기 처리하는 것이 안전하다.

## 5) 핵심 스키마 분석

### `CreatePostRequest`
- 필수: `title`, `author`
- 선택: `summary`, `contentMarkdown`, `thumbnailUrl`, `collaborators`, `status`
- 제약:
  - `title`: max 200
  - `summary`: max 300

### `PatchPostRequest`
- 모든 필드 선택
- 제약:
  - `title`: min 1, max 200
  - `summary`: max 300
- `PATCH`는 `application/json` 또는 `multipart/form-data` 둘 다 허용

### `PostAuthorRequest`
- 필수: `id`
- 선택: `nickname`, `profileImageUrl`
- 제약:
  - `id`: `pattern: .*\S.*` (공백만 있는 문자열 방지)

### `PostResponse`
- 주요 필드: `id(uuid)`, `title`, `summary`, `contentMarkdown`, `thumbnailUrl`, `author`, `collaborators[]`, `status`, `createdAt`, `updatedAt`

### 에러 래퍼
- 다수 API가 `ApiResponse<T>` 형태(`success`, `data`, `error`, `timestamp`)를 사용
- 단, 성공 응답은 어떤 API는 래퍼 없이 `PostResponse`, `PagedPostResponse`를 바로 반환

## 6) 엔드포인트별 동작 포인트

### 6.1 게시글 생성 `POST /v1/posts`
- 멀티파트 폼 구조:
  - `post`: `CreatePostRequest`
  - `thumbnail`: binary(optional)
- 성공: `201`, `PostResponse`
- 주의: 멀티파트에서 객체 파트(`post`) 직렬화 방식(JSON string part vs structured part)은 서버 구현에 따라 다를 수 있음.

### 6.2 게시글 수정 `PATCH /v1/posts/{postId}`
- `application/json`과 `multipart/form-data` 둘 다 지원
- 썸네일 변경이 필요 없으면 JSON 방식이 단순
- 썸네일 동시 갱신 시 멀티파트 사용

### 6.3 목록 계열 `GET /v1/posts*`
- 공통 쿼리:
  - `page` 기본 0
  - `size` 기본 20, 최대 100
- `status` 필터는 일부 목록 API에서 지원
- `/me`, `/drafts/me`는 인증 사용자 기준 조회

### 6.4 협업자 추가 `POST /v1/posts/{postId}/collaborators`
- 요청: `AddCollaboratorRequest`
  - 필수는 `collaborator`
  - `ownerId`는 optional
- 설명은 owner 전용이므로, 서버에서 토큰 사용자와 소유자 매칭을 검증하는 구조로 해석됨.

### 6.5 이미지 업로드 `POST /v1/posts/images`
- 멀티파트 단일 필드 `file` 업로드
- 성공: `ImageUploadResponse` (`url`, `key`, `contentType`, `size`)
- 실패: `413`(용량 초과), `415`(미디어 타입 불가)

## 7) 데이터 일관성/설계 리스크

### 7.1 인증 정의 불일치
- 문제: 일부 보호 리소스로 보이는 API에 `security` 미기재
- 영향: 클라이언트가 공개 API로 오해할 수 있음
- 권장: 보호 API는 스펙에 `security`를 일관 적용

### 7.2 `Authorization` 중복 정의
- 문제: `security`와 헤더 파라미터를 동시에 표기
- 영향: SDK 생성 시 중복 파라미터 노출 가능
- 권장: `security` 기반으로 통일하고 헤더 파라미터 직접 선언 제거

### 7.3 응답 포맷 혼재
- 문제: 성공 응답은 raw DTO, 에러는 `ApiResponse<T>` 래퍼를 쓰는 패턴 혼재
- 영향: 프론트 파서 분기 증가
- 권장: 성공/실패 모두 동일 envelope로 통일하거나, 전체 raw로 통일

### 7.4 콘텐츠 타입이 `*/*`
- 문제: 다수 응답 콘텐츠 타입이 `*/*`
- 영향: 코드 생성기/문서 UI에서 타입 추론 품질 저하
- 권장: `application/json`으로 명시

### 7.5 Draft API 공개 여부 불명확
- 문제: `/v1/posts/drafts`는 인증 미기재
- 영향: 공개 초안 노출 가능성(정책 미정 시 위험)
- 권장: 정책 의도 확정 후 스펙 반영

## 8) 클라이언트 구현 가이드 (tech_blog/Flutter 기준)
- HTTP 클라이언트 레이어에서 공통 처리:
  - 기본 `application/json`
  - 멀티파트 요청 빌더 분리(`create`, `patch`, `images/upload`)
  - 토큰 존재 시 `Authorization` 자동 주입
- 상태 enum은 서버 문자열과 정확히 매핑:
  - `Draft`, `Published`, `Deleted`
- API 응답 파싱 시 다음 두 케이스 모두 대응:
  - raw DTO 응답
  - `ApiResponse<T>` 래퍼 응답
- 페이징 기본값은 서버 기본과 동기화:
  - `page=0`, `size=20`

## 9) 빠른 검증 시나리오
- 시나리오 1: 게시글 생성(썸네일 없음) -> `201` 확인
- 시나리오 2: 게시글 생성(썸네일 포함) -> `thumbnailUrl` 반영 확인
- 시나리오 3: `PATCH` JSON 수정 -> 텍스트 필드 변경 확인
- 시나리오 4: `PATCH` 멀티파트 수정 -> 썸네일 변경 확인
- 시나리오 5: 권한 없는 사용자가 협업자 추가 -> `403` 확인
- 시나리오 6: 이미지 업로드 허용 타입/용량 경계 테스트 -> `200/413/415` 확인

## 10) 결론
- API는 게시글 협업/초안/이미지 업로드까지 포함한 실무형 구조를 갖추고 있다.
- 다만 인증 표기, 응답 envelope, 콘텐츠 타입 표기에서 문서 일관성이 떨어져 SDK 생성 및 프론트 구현 복잡도가 증가할 수 있다.
- 스펙 정제(보안/응답/콘텐츠 타입 통일)를 먼저 수행하면 클라이언트 안정성과 개발 속도를 크게 높일 수 있다.
