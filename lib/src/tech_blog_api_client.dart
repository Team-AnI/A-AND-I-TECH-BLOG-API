import 'dart:convert';

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

  /// API 서버 루트 URL입니다.
  final String baseUrl;

  /// v2 요청 시 사용할 디바이스 OS입니다.
  final String deviceOs;

  /// HTTP 클라이언트입니다.
  final Dio dio;

  /// Blog 게시글 목록을 조회합니다.
  Future<PagedPostResponse> listBlogs({
    String? accessToken,
    int page = 0,
    int size = 20,
    PostStatus? status,
  }) {
    return _getPagedPosts(
      path: '/v2/blogs',
      accessToken: accessToken,
      page: page,
      size: size,
      status: status,
    );
  }

  /// Lecture 게시글 목록을 조회합니다.
  Future<PagedPostResponse> listLectures({
    String? accessToken,
    int page = 0,
    int size = 20,
    PostStatus? status,
  }) {
    return _getPagedPosts(
      path: '/v2/lectures',
      accessToken: accessToken,
      page: page,
      size: size,
      status: status,
    );
  }

  /// 내 Blog 게시글 목록을 조회합니다.
  Future<PagedPostResponse> listMyBlogs({
    required String accessToken,
    int page = 0,
    int size = 20,
    PostStatus? status,
  }) {
    return _getPagedPosts(
      path: '/v2/blogs/me',
      accessToken: accessToken,
      page: page,
      size: size,
      status: status,
    );
  }

  /// 내 Lecture 게시글 목록을 조회합니다.
  Future<PagedPostResponse> listMyLectures({
    required String accessToken,
    int page = 0,
    int size = 20,
    PostStatus? status,
  }) {
    return _getPagedPosts(
      path: '/v2/lectures/me',
      accessToken: accessToken,
      page: page,
      size: size,
      status: status,
    );
  }

  /// Blog 초안 목록을 조회합니다.
  Future<PagedPostResponse> listBlogDrafts({
    required String accessToken,
    int page = 0,
    int size = 20,
  }) {
    return _getPagedPosts(
      path: '/v2/blogs/drafts',
      accessToken: accessToken,
      page: page,
      size: size,
    );
  }

  /// Lecture 초안 목록을 조회합니다.
  Future<PagedPostResponse> listLectureDrafts({
    required String accessToken,
    int page = 0,
    int size = 20,
  }) {
    return _getPagedPosts(
      path: '/v2/lectures/drafts',
      accessToken: accessToken,
      page: page,
      size: size,
    );
  }

  /// 내 Blog 초안 목록을 조회합니다.
  Future<PagedPostResponse> listMyBlogDrafts({
    required String accessToken,
    int page = 0,
    int size = 20,
  }) {
    return _getPagedPosts(
      path: '/v2/blogs/drafts/me',
      accessToken: accessToken,
      page: page,
      size: size,
    );
  }

  /// 내 Lecture 초안 목록을 조회합니다.
  Future<PagedPostResponse> listMyLectureDrafts({
    required String accessToken,
    int page = 0,
    int size = 20,
  }) {
    return _getPagedPosts(
      path: '/v2/lectures/drafts/me',
      accessToken: accessToken,
      page: page,
      size: size,
    );
  }

  /// 내 예약된 Blog 게시글 목록을 조회합니다.
  Future<PagedPostResponse> listMyScheduledBlogs({
    required String accessToken,
    int page = 0,
    int size = 20,
  }) {
    return _getPagedPosts(
      path: '/v2/blogs/scheduled/me',
      accessToken: accessToken,
      page: page,
      size: size,
    );
  }

  /// 내 예약된 Lecture 게시글 목록을 조회합니다.
  Future<PagedPostResponse> listMyScheduledLectures({
    required String accessToken,
    int page = 0,
    int size = 20,
  }) {
    return _getPagedPosts(
      path: '/v2/lectures/scheduled/me',
      accessToken: accessToken,
      page: page,
      size: size,
    );
  }

  /// Blog 게시글 상세를 조회합니다.
  Future<PostResponse> getBlog({
    required String postId,
    String? accessToken,
  }) {
    return _getPost(
      path: '/v2/blogs/$postId',
      accessToken: accessToken,
    );
  }

  /// Lecture 게시글 상세를 조회합니다.
  Future<PostResponse> getLecture({
    required String postId,
    String? accessToken,
  }) {
    return _getPost(
      path: '/v2/lectures/$postId',
      accessToken: accessToken,
    );
  }

  /// v2 게시글 목록을 조회합니다.
  @Deprecated(
    'Use listBlogs/listLectures. Generic /v2/posts endpoints are deprecated.',
  )
  Future<PagedPostResponse> listPostsV2({
    String? accessToken,
    int page = 0,
    int size = 20,
    PostStatus? status,
    PostType? type,
  }) {
    return switch (type) {
      PostType.blog => listBlogs(
          accessToken: accessToken,
          page: page,
          size: size,
          status: status,
        ),
      PostType.lecture => listLectures(
          accessToken: accessToken,
          page: page,
          size: size,
          status: status,
        ),
      null => _getPagedPosts(
          path: '/v2/posts',
          accessToken: accessToken,
          page: page,
          size: size,
          status: status,
        ),
    };
  }

  /// v2 초안 게시글 목록을 조회합니다.
  @Deprecated(
    'Use listBlogDrafts/listLectureDrafts. Generic /v2/posts endpoints are deprecated.',
  )
  Future<PagedPostResponse> listDraftsV2({
    required String accessToken,
    int page = 0,
    int size = 20,
    PostType? type,
  }) {
    return switch (type) {
      PostType.blog => listBlogDrafts(
          accessToken: accessToken,
          page: page,
          size: size,
        ),
      PostType.lecture => listLectureDrafts(
          accessToken: accessToken,
          page: page,
          size: size,
        ),
      null => _getPagedPosts(
          path: '/v2/posts/drafts',
          accessToken: accessToken,
          page: page,
          size: size,
        ),
    };
  }

  /// v2 현재 사용자 기준 게시글 목록을 조회합니다.
  @Deprecated(
    'Use listMyBlogs/listMyLectures. Generic /v2/posts endpoints are deprecated.',
  )
  Future<PagedPostResponse> listMyPostsV2({
    required String accessToken,
    int page = 0,
    int size = 20,
    PostStatus? status,
    PostType? type,
  }) {
    return switch (type) {
      PostType.blog => listMyBlogs(
          accessToken: accessToken,
          page: page,
          size: size,
          status: status,
        ),
      PostType.lecture => listMyLectures(
          accessToken: accessToken,
          page: page,
          size: size,
          status: status,
        ),
      null => _getPagedPosts(
          path: '/v2/posts/me',
          accessToken: accessToken,
          page: page,
          size: size,
          status: status,
        ),
    };
  }

  /// v2 현재 사용자 기준 초안 목록을 조회합니다.
  @Deprecated(
    'Use listMyBlogDrafts/listMyLectureDrafts. Generic /v2/posts endpoints are deprecated.',
  )
  Future<PagedPostResponse> listMyDraftsV2({
    required String accessToken,
    int page = 0,
    int size = 20,
    PostType? type,
  }) {
    return switch (type) {
      PostType.blog => listMyBlogDrafts(
          accessToken: accessToken,
          page: page,
          size: size,
        ),
      PostType.lecture => listMyLectureDrafts(
          accessToken: accessToken,
          page: page,
          size: size,
        ),
      null => _getPagedPosts(
          path: '/v2/posts/drafts/me',
          accessToken: accessToken,
          page: page,
          size: size,
        ),
    };
  }

  /// v2 현재 사용자 기준 예약 게시글 목록을 조회합니다.
  @Deprecated(
    'Use listMyScheduledBlogs/listMyScheduledLectures. Generic /v2/posts endpoints are deprecated.',
  )
  Future<PagedPostResponse> listMyScheduledPostsV2({
    required String accessToken,
    int page = 0,
    int size = 20,
    PostType? type,
  }) {
    return switch (type) {
      PostType.blog => listMyScheduledBlogs(
          accessToken: accessToken,
          page: page,
          size: size,
        ),
      PostType.lecture => listMyScheduledLectures(
          accessToken: accessToken,
          page: page,
          size: size,
        ),
      null => _getPagedPosts(
          path: '/v2/posts/scheduled/me',
          accessToken: accessToken,
          page: page,
          size: size,
        ),
    };
  }

  /// v2 게시글 상세를 조회합니다.
  @Deprecated(
    'Use getBlog/getLecture. Generic /v2/posts endpoints are deprecated.',
  )
  Future<PostResponse> getPostV2({
    required String postId,
    String? accessToken,
    PostType? type,
  }) {
    return switch (type) {
      PostType.blog => getBlog(postId: postId, accessToken: accessToken),
      PostType.lecture => getLecture(postId: postId, accessToken: accessToken),
      null => _getPost(
          path: '/v2/posts/$postId',
          accessToken: accessToken,
        ),
    };
  }

  /// v2 게시글을 생성합니다.
  Future<PostResponse> createPostV2({
    required String accessToken,
    required CreatePostRequest post,
    MultipartFile? thumbnail,
  }) {
    return _createPost(
      accessToken: accessToken,
      post: post,
      thumbnail: thumbnail,
    );
  }

  /// v2 게시글을 부분 수정합니다.
  Future<PostResponse> patchPostV2({
    required String postId,
    required String accessToken,
    required PatchPostRequest post,
    MultipartFile? thumbnail,
  }) {
    return _patchPost(
      postId: postId,
      accessToken: accessToken,
      post: post,
      thumbnail: thumbnail,
    );
  }

  /// v2 게시글 삭제 여부를 반환합니다.
  Future<bool> deletePostV2({
    required String postId,
    required String accessToken,
  }) {
    return _deletePost(
      postId: postId,
      accessToken: accessToken,
    );
  }

  /// v2 게시글에 협업자를 추가합니다.
  Future<PostResponse> addCollaboratorV2({
    required String postId,
    required String accessToken,
    required AddCollaboratorRequest request,
  }) {
    return _addCollaborator(
      postId: postId,
      accessToken: accessToken,
      request: request,
    );
  }

  /// v2 이미지를 업로드하고 공개 메타데이터를 반환합니다.
  Future<ImageUploadResponse> uploadImageV2({
    required String accessToken,
    required MultipartFile file,
  }) {
    return _uploadImage(
      accessToken: accessToken,
      file: file,
    );
  }

  /// 게시글 목록을 조회합니다.
  @Deprecated(
    'Use listBlogs/listLectures. Generic /v2/posts endpoints are deprecated.',
  )
  Future<PagedPostResponse> listPosts({
    int page = 0,
    int size = 20,
    PostStatus? status,
    PostType? type,
    String? accessToken,
  }) {
    return listPostsV2(
      accessToken: accessToken,
      page: page,
      size: size,
      status: status,
      type: type,
    );
  }

  /// 초안 게시글 목록을 조회합니다.
  @Deprecated(
    'Use listBlogDrafts/listLectureDrafts. Generic /v2/posts endpoints are deprecated.',
  )
  Future<PagedPostResponse> listDrafts({
    int page = 0,
    int size = 20,
    PostType? type,
    String? accessToken,
  }) {
    return listDraftsV2(
      accessToken: accessToken ?? '',
      page: page,
      size: size,
      type: type,
    );
  }

  /// 현재 사용자 기준(소유자/협업자) 게시글 목록을 조회합니다.
  @Deprecated(
    'Use listMyBlogs/listMyLectures. Generic /v2/posts endpoints are deprecated.',
  )
  Future<PagedPostResponse> listMyPosts({
    required String accessToken,
    int page = 0,
    int size = 20,
    PostStatus? status,
    PostType? type,
  }) {
    return listMyPostsV2(
      accessToken: accessToken,
      page: page,
      size: size,
      status: status,
      type: type,
    );
  }

  /// 현재 사용자 기준 초안 목록을 조회합니다.
  @Deprecated(
    'Use listMyBlogDrafts/listMyLectureDrafts. Generic /v2/posts endpoints are deprecated.',
  )
  Future<PagedPostResponse> listMyDrafts({
    required String accessToken,
    int page = 0,
    int size = 20,
    PostType? type,
  }) {
    return listMyDraftsV2(
      accessToken: accessToken,
      page: page,
      size: size,
      type: type,
    );
  }

  /// 현재 사용자 기준 예약 게시글 목록을 조회합니다.
  @Deprecated(
    'Use listMyScheduledBlogs/listMyScheduledLectures. Generic /v2/posts endpoints are deprecated.',
  )
  Future<PagedPostResponse> listMyScheduledPosts({
    required String accessToken,
    int page = 0,
    int size = 20,
    PostType? type,
  }) {
    return listMyScheduledPostsV2(
      accessToken: accessToken,
      page: page,
      size: size,
      type: type,
    );
  }

  /// 게시글 상세를 조회합니다.
  @Deprecated(
    'Use getBlog/getLecture. Generic /v2/posts endpoints are deprecated.',
  )
  Future<PostResponse> getPost({
    required String postId,
    PostType? type,
    String? accessToken,
  }) {
    return getPostV2(
      postId: postId,
      accessToken: accessToken,
      type: type,
    );
  }

  /// 게시글을 생성합니다.
  Future<PostResponse> createPost({
    required CreatePostRequest post,
    MultipartFile? thumbnail,
    String? accessToken,
  }) {
    return _createPost(
      accessToken: accessToken,
      post: post,
      thumbnail: thumbnail,
    );
  }

  /// 게시글을 부분 수정합니다.
  Future<PostResponse> patchPost({
    required String postId,
    required String accessToken,
    required PatchPostRequest post,
    MultipartFile? thumbnail,
  }) {
    return _patchPost(
      postId: postId,
      accessToken: accessToken,
      post: post,
      thumbnail: thumbnail,
    );
  }

  /// 게시글을 삭제합니다.
  Future<bool> deletePost({
    required String postId,
    String? accessToken,
  }) {
    return _deletePost(
      postId: postId,
      accessToken: accessToken,
    );
  }

  /// 게시글에 협업자를 추가합니다.
  Future<PostResponse> addCollaborator({
    required String postId,
    required String accessToken,
    required AddCollaboratorRequest request,
  }) {
    return _addCollaborator(
      postId: postId,
      accessToken: accessToken,
      request: request,
    );
  }

  /// 이미지를 업로드하고 공개 메타데이터를 반환합니다.
  Future<ImageUploadResponse> uploadImage({
    required MultipartFile file,
    String? accessToken,
  }) {
    return _uploadImage(
      accessToken: accessToken,
      file: file,
    );
  }

  Future<PagedPostResponse> _getPagedPosts({
    required String path,
    required String? accessToken,
    required int page,
    required int size,
    PostStatus? status,
  }) async {
    final response = await dio.requestUri<dynamic>(
      _resolveUri(path).replace(
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
          if (status != null) 'status': status.toApi(),
        },
      ),
      options: _v2Options(method: 'GET', accessToken: accessToken),
    );
    final data = _unwrapV2DataMap(response);
    try {
      return PagedPostResponse.fromJson(data);
    } on FormatException {
      throw TechBlogApiException(
        'Invalid paged post response',
        statusCode: response.statusCode,
      );
    }
  }

  Future<PostResponse> _getPost({
    required String path,
    required String? accessToken,
  }) async {
    final response = await dio.requestUri<dynamic>(
      _resolveUri(path),
      options: _v2Options(method: 'GET', accessToken: accessToken),
    );
    final data = _unwrapV2DataMap(response);
    return PostResponse.fromJson(data);
  }

  Future<PostResponse> _createPost({
    required String? accessToken,
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
      _resolveUri('/v2/posts'),
      data: FormData.fromMap(payload),
      options: _v2Options(method: 'POST', accessToken: accessToken),
    );
    final data = _unwrapV2DataMap(response);
    return PostResponse.fromJson(data);
  }

  Future<PostResponse> _patchPost({
    required String postId,
    required String? accessToken,
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
      _resolveUri('/v2/posts/$postId'),
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

  Future<bool> _deletePost({
    required String postId,
    required String? accessToken,
  }) async {
    final response = await dio.requestUri<dynamic>(
      _resolveUri('/v2/posts/$postId'),
      options: _v2Options(method: 'DELETE', accessToken: accessToken),
    );
    final data = _unwrapV2DataMap(response);
    final deleted = data['deleted'];
    if (deleted is bool) {
      return deleted;
    }
    return false;
  }

  Future<PostResponse> _addCollaborator({
    required String postId,
    required String? accessToken,
    required AddCollaboratorRequest request,
  }) async {
    final response = await dio.requestUri<dynamic>(
      _resolveUri('/v2/posts/$postId/collaborators'),
      data: request.toJson(),
      options: _v2Options(
        method: 'POST',
        accessToken: accessToken,
        jsonBody: true,
      ),
    );
    final data = _unwrapV2DataMap(response);
    return PostResponse.fromJson(data);
  }

  Future<ImageUploadResponse> _uploadImage({
    required String? accessToken,
    required MultipartFile file,
  }) async {
    final response = await dio.requestUri<dynamic>(
      _resolveUri('/v2/posts/images'),
      data: FormData.fromMap({'file': file}),
      options: _v2Options(method: 'POST', accessToken: accessToken),
    );
    final data = _unwrapV2DataMap(response);
    return ImageUploadResponse.fromJson(data);
  }

  Uri _resolveUri(String path) {
    return Uri.parse(baseUrl).resolve(path);
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
    final normalizedAccessToken = accessToken?.trim();
    final hasAccessToken =
        normalizedAccessToken != null && normalizedAccessToken.isNotEmpty;

    return Options(
      method: method,
      headers: {
        'Accept': 'application/json',
        'deviceOS': deviceOs,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        if (hasAccessToken) 'Authenticate': 'Bearer $normalizedAccessToken',
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
