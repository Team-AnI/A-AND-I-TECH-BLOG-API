import 'dart:convert';

import 'package:aandi_api_endpoints/aandi_api_endpoints.dart';
import 'package:dio/dio.dart';

import 'add_collaborator_request.dart';
import 'create_post_request.dart';
import 'image_upload_response.dart';
import 'paged_post_response.dart';
import 'patch_post_request.dart';
import 'post_response.dart';
import 'post_status.dart';
import 'post_type.dart';
import 'tech_blog_api_exception.dart';

/// Tech Blog 백엔드와 통신하는 HTTP 클라이언트입니다.
class TechBlogApiClient {
  /// [baseUrl]은 API 서버 루트 URL입니다. (예: `https://api.aandiclub.com`)
  ///
  /// [dio]를 주입하면 테스트/인터셉터 구성을 재사용할 수 있습니다.
  TechBlogApiClient({
    required this.baseUrl,
    this.deviceOs = 'android',
    Dio? dio,
  }) : dio = dio ?? Dio();

  /// API 서버 루트 URL
  final String baseUrl;

  /// v2 요청 시 사용할 디바이스 OS입니다.
  final String deviceOs;

  /// HTTP 클라이언트
  final Dio dio;

  /// v2 게시글 목록을 조회합니다.
  ///
  /// [accessToken]이 null이면 인증 헤더 없이 공개 목록을 조회합니다.
  Future<PagedPostResponse> listPostsV2({
    String? accessToken,
    int page = 0,
    int size = 20,
    PostStatus? status,
    PostType? type,
  }) async {
    final response = await dio.requestUri<dynamic>(
      Uri.parse('$baseUrl/v2/posts').replace(
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
          if (status != null) 'status': status.toApi(),
          if (type != null) 'type': type.toApi(),
        },
      ),
      options: _v2Options(method: 'GET', accessToken: accessToken),
    );
    final data = _unwrapV2DataMap(response);
    return PagedPostResponse.fromJson(data);
  }

  /// v2 초안 게시글 목록을 조회합니다.
  Future<PagedPostResponse> listDraftsV2({
    required String accessToken,
    int page = 0,
    int size = 20,
    PostType? type,
  }) async {
    final response = await dio.requestUri<dynamic>(
      Uri.parse('$baseUrl/v2/posts/drafts').replace(
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
          if (type != null) 'type': type.toApi(),
        },
      ),
      options: _v2Options(method: 'GET', accessToken: accessToken),
    );
    final data = _unwrapV2DataMap(response);
    return PagedPostResponse.fromJson(data);
  }

  /// v2 현재 사용자 기준 게시글 목록을 조회합니다.
  Future<PagedPostResponse> listMyPostsV2({
    required String accessToken,
    int page = 0,
    int size = 20,
    PostStatus? status,
    PostType? type,
  }) async {
    final response = await dio.requestUri<dynamic>(
      Uri.parse('$baseUrl/v2/posts/me').replace(
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
          if (status != null) 'status': status.toApi(),
          if (type != null) 'type': type.toApi(),
        },
      ),
      options: _v2Options(method: 'GET', accessToken: accessToken),
    );
    final data = _unwrapV2DataMap(response);
    return PagedPostResponse.fromJson(data);
  }

  /// v2 현재 사용자 기준 초안 목록을 조회합니다.
  Future<PagedPostResponse> listMyDraftsV2({
    required String accessToken,
    int page = 0,
    int size = 20,
    PostType? type,
  }) async {
    final response = await dio.requestUri<dynamic>(
      Uri.parse('$baseUrl/v2/posts/drafts/me').replace(
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
          if (type != null) 'type': type.toApi(),
        },
      ),
      options: _v2Options(method: 'GET', accessToken: accessToken),
    );
    final data = _unwrapV2DataMap(response);
    return PagedPostResponse.fromJson(data);
  }

  /// v2 게시글 상세를 조회합니다.
  Future<PostResponse> getPostV2({
    required String postId,
    String? accessToken,
  }) async {
    final response = await dio.requestUri<dynamic>(
      Uri.parse('$baseUrl/v2/posts/$postId'),
      options: _v2Options(method: 'GET', accessToken: accessToken),
    );
    final data = _unwrapV2DataMap(response);
    return PostResponse.fromJson(data);
  }

  /// v2 게시글을 생성합니다.
  Future<PostResponse> createPostV2({
    required String accessToken,
    required CreatePostRequest post,
    MultipartFile? thumbnail,
  }) async {
    final payload = <String, dynamic>{
      'post': _jsonMultipartPart(post.toJson()),
    };
    if (thumbnail != null) {
      payload['thumbnail'] = thumbnail;
    }
    final response = await dio.requestUri<dynamic>(
      Uri.parse('$baseUrl/v2/posts'),
      data: FormData.fromMap(payload),
      options: _v2Options(method: 'POST', accessToken: accessToken),
    );
    final data = _unwrapV2DataMap(response);
    return PostResponse.fromJson(data);
  }

  /// v2 게시글을 부분 수정합니다.
  Future<PostResponse> patchPostV2({
    required String postId,
    required String accessToken,
    required PatchPostRequest post,
    MultipartFile? thumbnail,
  }) async {
    final requestData = thumbnail == null
        ? post.toJson()
        : FormData.fromMap({
            'post': _jsonMultipartPart(post.toJson()),
            'thumbnail': thumbnail,
          });
    final response = await dio.requestUri<dynamic>(
      Uri.parse('$baseUrl/v2/posts/$postId'),
      data: requestData,
      options: _v2Options(
        method: 'PATCH',
        accessToken: accessToken,
        jsonBody: thumbnail == null,
      ),
    );
    final data = _unwrapV2DataMap(response);
    return PostResponse.fromJson(data);
  }

  /// v2 게시글 삭제 여부를 반환합니다.
  Future<bool> deletePostV2({
    required String postId,
    required String accessToken,
  }) async {
    final response = await dio.requestUri<dynamic>(
      Uri.parse('$baseUrl/v2/posts/$postId'),
      options: _v2Options(method: 'DELETE', accessToken: accessToken),
    );
    final data = _unwrapV2DataMap(response);
    final deleted = data['deleted'];
    if (deleted is bool) {
      return deleted;
    }
    return false;
  }

  /// v2 게시글에 협업자를 추가합니다.
  Future<PostResponse> addCollaboratorV2({
    required String postId,
    required String accessToken,
    required AddCollaboratorRequest request,
  }) async {
    final response = await dio.requestUri<dynamic>(
      Uri.parse('$baseUrl/v2/posts/$postId/collaborators'),
      data: {'collaborator': request.collaborator.toJson()},
      options: _v2Options(
        method: 'POST',
        accessToken: accessToken,
        jsonBody: true,
      ),
    );
    final data = _unwrapV2DataMap(response);
    return PostResponse.fromJson(data);
  }

  /// v2 이미지를 업로드하고 공개 메타데이터를 반환합니다.
  Future<ImageUploadResponse> uploadImageV2({
    required String accessToken,
    required MultipartFile file,
  }) async {
    final response = await dio.requestUri<dynamic>(
      Uri.parse('$baseUrl/v2/posts/images'),
      data: FormData.fromMap({'file': file}),
      options: _v2Options(method: 'POST', accessToken: accessToken),
    );
    final data = _unwrapV2DataMap(response);
    return ImageUploadResponse.fromJson(data);
  }

  /// 게시글 목록을 조회합니다.
  ///
  /// [page]/[size]로 페이징하고, [status]로 상태 필터를 적용할 수 있습니다.
  /// `size`의 서버 최대값은 OpenAPI 기준 100입니다.
  Future<PagedPostResponse> listPosts({
    int page = 0,
    int size = 20,
    PostStatus? status,
  }) async {
    final queryParameters = {
      'page': page.toString(),
      'size': size.toString(),
      if (status != null) 'status': status.toApi(),
    };

    final response = await dio.requestUri<dynamic>(
      Uri.parse(
        AandiApiUrlResolver.resolve(baseUrl, AandiApiEndpointTemplate.posts),
      ).replace(queryParameters: queryParameters),
      options: Options(
        method: 'GET',
        headers: {'Accept': 'application/json'},
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );

    final statusCode = response.statusCode ?? 0;
    final decoded = _decodeResponseMap(response.data, statusCode: statusCode);

    if (statusCode < 200 || statusCode >= 300) {
      final error = decoded['error'];
      final message = error is Map<String, dynamic>
          ? error['message']?.toString() ?? '요청에 실패했습니다.'
          : '요청에 실패했습니다.';
      final code =
          error is Map<String, dynamic> ? error['code']?.toString() : null;
      throw TechBlogApiException(message, statusCode: statusCode, code: code);
    }

    try {
      return PagedPostResponse.fromJson(decoded);
    } on FormatException {
      throw TechBlogApiException(
        'Invalid paged post response',
        statusCode: statusCode,
      );
    }
  }

  /// 초안 게시글 목록을 조회합니다.
  Future<PagedPostResponse> listDrafts({int page = 0, int size = 20}) async {
    final response = await dio.requestUri<dynamic>(
      Uri.parse(
        AandiApiUrlResolver.resolve(
            baseUrl, AandiApiEndpointTemplate.draftPosts),
      ).replace(
        queryParameters: {'page': page.toString(), 'size': size.toString()},
      ),
      options: Options(
        method: 'GET',
        headers: {'Accept': 'application/json'},
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );

    final statusCode = response.statusCode ?? 0;
    final decoded = _decodeResponseMap(response.data, statusCode: statusCode);

    if (statusCode < 200 || statusCode >= 300) {
      _throwApiError(decoded, statusCode: statusCode);
    }

    try {
      return PagedPostResponse.fromJson(decoded);
    } on FormatException {
      throw TechBlogApiException(
        'Invalid paged post response',
        statusCode: statusCode,
      );
    }
  }

  /// 현재 사용자 기준(소유자/협업자) 게시글 목록을 조회합니다.
  ///
  /// [accessToken]은 Bearer 토큰 문자열입니다.
  /// 토큰이 유효하지 않으면 일반적으로 401/403 [TechBlogApiException]이 발생합니다.
  Future<PagedPostResponse> listMyPosts({
    required String accessToken,
    int page = 0,
    int size = 20,
    PostStatus? status,
  }) async {
    final response = await dio.requestUri<dynamic>(
      Uri.parse(
        AandiApiUrlResolver.resolve(baseUrl, AandiApiEndpointTemplate.myPosts),
      ).replace(
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
          if (status != null) 'status': status.toApi(),
        },
      ),
      options: Options(
        method: 'GET',
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );

    final statusCode = response.statusCode ?? 0;
    final decoded = _decodeResponseMap(response.data, statusCode: statusCode);

    if (statusCode < 200 || statusCode >= 300) {
      _throwApiError(decoded, statusCode: statusCode);
    }

    try {
      return PagedPostResponse.fromJson(decoded);
    } on FormatException {
      throw TechBlogApiException(
        'Invalid paged post response',
        statusCode: statusCode,
      );
    }
  }

  /// 현재 사용자 기준(소유자/협업자) 초안 목록을 조회합니다.
  ///
  /// [accessToken]이 유효하지 않으면 401/403 [TechBlogApiException]이 발생할 수 있습니다.
  Future<PagedPostResponse> listMyDrafts({
    required String accessToken,
    int page = 0,
    int size = 20,
  }) async {
    final response = await dio.requestUri<dynamic>(
      Uri.parse(
        AandiApiUrlResolver.resolve(
            baseUrl, AandiApiEndpointTemplate.myDraftPosts),
      ).replace(
        queryParameters: {'page': page.toString(), 'size': size.toString()},
      ),
      options: Options(
        method: 'GET',
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );

    final statusCode = response.statusCode ?? 0;
    final decoded = _decodeResponseMap(response.data, statusCode: statusCode);

    if (statusCode < 200 || statusCode >= 300) {
      _throwApiError(decoded, statusCode: statusCode);
    }

    try {
      return PagedPostResponse.fromJson(decoded);
    } on FormatException {
      throw TechBlogApiException(
        'Invalid paged post response',
        statusCode: statusCode,
      );
    }
  }

  /// 게시글 상세를 조회합니다.
  Future<PostResponse> getPost({required String postId}) async {
    final response = await dio.requestUri<dynamic>(
      Uri.parse(
        AandiApiUrlResolver.resolve(
            baseUrl, AandiApiEndpointPath.postById(postId)),
      ),
      options: Options(
        method: 'GET',
        headers: {'Accept': 'application/json'},
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );

    final statusCode = response.statusCode ?? 0;
    final decoded = _decodeResponseMap(response.data, statusCode: statusCode);

    if (statusCode < 200 || statusCode >= 300) {
      _throwApiError(decoded, statusCode: statusCode);
    }

    return PostResponse.fromJson(decoded);
  }

  /// 게시글을 생성합니다.
  ///
  /// [post]는 `post` 필드의 JSON 파트로 직렬화되어 전송됩니다.
  /// [thumbnail]이 있으면 `thumbnail` 바이너리 필드를 포함한 multipart 요청으로 전송됩니다.
  /// [accessToken]이 있으면 Authorization 헤더를 추가합니다.
  Future<PostResponse> createPost({
    required CreatePostRequest post,
    MultipartFile? thumbnail,
    String? accessToken,
  }) async {
    final payload = <String, dynamic>{
      'post': _jsonMultipartPart(post.toJson()),
    };
    if (thumbnail != null) {
      payload['thumbnail'] = thumbnail;
    }
    final formData = FormData.fromMap(payload);

    final response = await dio.requestUri<dynamic>(
      Uri.parse(
        AandiApiUrlResolver.resolve(baseUrl, AandiApiEndpointTemplate.posts),
      ),
      data: formData,
      options: Options(
        method: 'POST',
        headers: {
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );

    final statusCode = response.statusCode ?? 0;
    final decoded = _decodeResponseMap(response.data, statusCode: statusCode);

    if (statusCode < 200 || statusCode >= 300) {
      _throwApiError(decoded, statusCode: statusCode);
    }

    return PostResponse.fromJson(decoded);
  }

  /// 게시글을 부분 수정합니다.
  ///
  /// [thumbnail]이 없으면 JSON PATCH, 있으면 multipart PATCH로 요청합니다.
  /// multipart 모드에서는 [post]가 `post` JSON 파트로 직렬화됩니다.
  Future<PostResponse> patchPost({
    required String postId,
    required String accessToken,
    required PatchPostRequest post,
    MultipartFile? thumbnail,
  }) async {
    final requestData = thumbnail == null
        ? post.toJson()
        : FormData.fromMap({
            'post': _jsonMultipartPart(post.toJson()),
            'thumbnail': thumbnail,
          });
    final headers = <String, String>{
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
      if (thumbnail == null) 'Content-Type': 'application/json',
    };

    final response = await dio.requestUri<dynamic>(
      Uri.parse(
        AandiApiUrlResolver.resolve(
            baseUrl, AandiApiEndpointPath.postById(postId)),
      ),
      data: requestData,
      options: Options(
        method: 'PATCH',
        headers: headers,
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );

    final statusCode = response.statusCode ?? 0;
    final decoded = _decodeResponseMap(response.data, statusCode: statusCode);

    if (statusCode < 200 || statusCode >= 300) {
      _throwApiError(decoded, statusCode: statusCode);
    }

    return PostResponse.fromJson(decoded);
  }

  /// 게시글을 삭제합니다.
  ///
  /// 서버가 반환한 `data`에서 첫 번째 bool 값을 읽어 삭제 여부를 반환합니다.
  Future<bool> deletePost({required String postId, String? accessToken}) async {
    final response = await dio.requestUri<dynamic>(
      Uri.parse(
        AandiApiUrlResolver.resolve(
            baseUrl, AandiApiEndpointPath.postById(postId)),
      ),
      options: Options(
        method: 'DELETE',
        headers: {
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );

    final statusCode = response.statusCode ?? 0;
    final decoded = _decodeResponseMap(response.data, statusCode: statusCode);

    if (statusCode < 200 || statusCode >= 300) {
      _throwApiError(decoded, statusCode: statusCode);
    }

    final data = decoded['data'];
    if (data is bool) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final firstBool = data.values.whereType<bool>();
      if (firstBool.isNotEmpty) {
        return firstBool.first;
      }
    }
    if (data is Map) {
      final firstBool = data.values.whereType<bool>();
      if (firstBool.isNotEmpty) {
        return firstBool.first;
      }
    }
    return true;
  }

  /// 게시글에 협업자를 추가합니다.
  ///
  /// 소유자 권한이 없으면 일반적으로 403 [TechBlogApiException]이 발생합니다.
  Future<PostResponse> addCollaborator({
    required String postId,
    required String accessToken,
    required AddCollaboratorRequest request,
  }) async {
    final response = await dio.requestUri<dynamic>(
      Uri.parse(
        AandiApiUrlResolver.resolve(
          baseUrl,
          AandiApiEndpointPath.postCollaborators(postId),
        ),
      ),
      data: request.toJson(),
      options: Options(
        method: 'POST',
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );

    final statusCode = response.statusCode ?? 0;
    final decoded = _decodeResponseMap(response.data, statusCode: statusCode);

    if (statusCode < 200 || statusCode >= 300) {
      _throwApiError(decoded, statusCode: statusCode);
    }

    return PostResponse.fromJson(decoded);
  }

  /// 이미지를 업로드하고 공개 메타데이터를 반환합니다.
  ///
  /// 서버 제약 위반 시 413(용량 초과), 415(미디어 타입 불일치) 오류가 발생할 수 있습니다.
  Future<ImageUploadResponse> uploadImage({required MultipartFile file}) async {
    final response = await dio.requestUri<dynamic>(
      Uri.parse(
        AandiApiUrlResolver.resolve(
            baseUrl, AandiApiEndpointTemplate.postImages),
      ),
      data: FormData.fromMap({'file': file}),
      options: Options(
        method: 'POST',
        headers: {'Accept': 'application/json'},
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );

    final statusCode = response.statusCode ?? 0;
    final decoded = _decodeResponseMap(response.data, statusCode: statusCode);

    if (statusCode < 200 || statusCode >= 300) {
      _throwApiError(decoded, statusCode: statusCode);
    }

    return ImageUploadResponse.fromJson(decoded);
  }

  /// 응답 본문을 `Map<String, dynamic>`으로 정규화합니다.
  ///
  /// Map / JSON string 형태를 허용하고, 그 외 형태는 예외를 발생시킵니다.
  Map<String, dynamic> _decodeResponseMap(
    dynamic responseData, {
    required int statusCode,
  }) {
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    if (responseData is Map) {
      return responseData.map((key, value) => MapEntry(key.toString(), value));
    }
    if (responseData is String) {
      try {
        final decoded = jsonDecode(responseData);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } on FormatException {
        // fall through
      }
    }

    throw TechBlogApiException(
      'Invalid response shape',
      statusCode: statusCode,
    );
  }

  /// 서버 오류 payload를 [TechBlogApiException]으로 변환해 던집니다.
  Never _throwApiError(
    Map<String, dynamic> decoded, {
    required int statusCode,
  }) {
    final error = decoded['error'];
    final message = error is Map<String, dynamic>
        ? error['message']?.toString() ?? '요청에 실패했습니다.'
        : '요청에 실패했습니다.';
    final code =
        error is Map<String, dynamic> ? error['code']?.toString() : null;
    final value =
        error is Map<String, dynamic> ? error['value']?.toString() : null;
    final alert =
        error is Map<String, dynamic> ? error['alert']?.toString() : null;
    throw TechBlogApiException(
      alert ?? message,
      statusCode: statusCode,
      code: code,
      value: value,
      alert: alert,
    );
  }

  Options _v2Options({
    required String method,
    String? accessToken,
    bool jsonBody = false,
  }) {
    return Options(
      method: method,
      headers: {
        'Accept': 'application/json',
        'deviceOS': deviceOs,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        if (accessToken != null && accessToken.isNotEmpty)
          'Authenticate': 'Bearer $accessToken',
        if (jsonBody) 'Content-Type': 'application/json',
      },
      responseType: ResponseType.plain,
      validateStatus: (_) => true,
    );
  }

  MultipartFile _jsonMultipartPart(Map<String, dynamic> payload) {
    return MultipartFile.fromString(
      jsonEncode(payload),
      filename: 'post.json',
      contentType: DioMediaType.parse(Headers.jsonContentType),
    );
  }

  Map<String, dynamic> _unwrapV2DataMap(Response<dynamic> response) {
    final statusCode = response.statusCode ?? 0;
    final decoded = _decodeResponseMap(response.data, statusCode: statusCode);
    if (statusCode < 200 || statusCode >= 300) {
      _throwApiError(decoded, statusCode: statusCode);
    }
    final success = decoded['success'];
    if (success == false) {
      _throwApiError(decoded, statusCode: statusCode);
    }
    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    throw TechBlogApiException(
      'Invalid response data shape',
      statusCode: statusCode,
    );
  }
}
