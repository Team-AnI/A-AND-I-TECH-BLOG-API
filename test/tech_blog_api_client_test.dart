import 'dart:convert';
import 'dart:typed_data';

import 'package:aandi_tech_blog/aandi_tech_blog.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const baseUrl = 'https://api.example.com';
  const postId = '9f35dd42-ff17-4e47-8f66-fbc6fce13b8a';

  group('TechBlogApiClient.listPosts', () {
    test('type이 blog면 /v2/blogs 경로로 요청하고 응답을 파싱한다', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, _, __) async {
          expect(options.method, 'GET');
          expect(options.uri, Uri.parse('$baseUrl/v2/blogs?page=0&size=20'));
          expect(_headerValue(options.headers, 'accept'), 'application/json');
          expect(_headerValue(options.headers, 'deviceOS'), 'android');
          expect(_headerValue(options.headers, 'timestamp'), isNotEmpty);

          return _jsonResponse(
            _v2Envelope({
              'items': [
                {
                  'id': postId,
                  'title': 'First post',
                  'summary': 'Summary',
                  'contentMarkdown': '# Hello',
                  'thumbnailUrl': 'https://cdn.example.com/thumb.jpg',
                  'author': {
                    'id': 'owner-1',
                    'nickname': 'Owner',
                    'profileImageUrl': 'https://cdn.example.com/owner.jpg',
                  },
                  'collaborators': const [],
                  'type': 'Blog',
                  'status': 'Scheduled',
                  'scheduledPublishAt': '2026-05-02T10:00:00Z',
                  'createdAt': '2026-03-09T10:00:00Z',
                  'updatedAt': '2026-03-09T12:00:00Z',
                },
              ],
              'page': 0,
              'size': 20,
              'totalElements': 1,
              'totalPages': 1,
            }),
            200,
          );
        },
      );

      final page = await client.listBlogs();

      expect(page.items, hasLength(1));
      expect(page.items.single.type, PostType.blog);
      expect(page.items.single.status, PostStatus.scheduled);
      expect(
        page.items.single.scheduledPublishAt,
        DateTime.parse('2026-05-02T10:00:00Z'),
      );
    });
  });

  group('TechBlogApiClient.getPost', () {
    test('type이 lecture면 /v2/lectures/{id} 경로로 상세를 조회한다', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, _, __) async {
          expect(options.method, 'GET');
          expect(options.uri, Uri.parse('$baseUrl/v2/lectures/$postId'));

          return _jsonResponse(
            _v2Envelope({
              'id': postId,
              'title': 'Lecture post',
              'author': {'id': 'owner-1'},
              'collaborators': const [],
              'type': 'Lecture',
              'status': 'Published',
              'publishedAt': '2026-04-09T12:00:00Z',
            }),
            200,
          );
        },
      );

      final post = await client.getLecture(postId: postId);

      expect(post.type, PostType.lecture);
      expect(post.status, PostStatus.published);
      expect(post.publishedAt, DateTime.parse('2026-04-09T12:00:00Z'));
    });

    test('API 오류 payload를 TechBlogApiException으로 변환한다', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (_, __, ___) async => _jsonResponse(
          {
            'success': false,
            'data': null,
            'error': {'message': '게시글을 찾을 수 없습니다.', 'code': 'NOT_FOUND'},
          },
          404,
        ),
      );

      await expectLater(
        client.getBlog(postId: postId),
        throwsA(
          _isApiException(
            message: '게시글을 찾을 수 없습니다.',
            statusCode: 404,
            code: 'NOT_FOUND',
          ),
        ),
      );
    });
  });

  group('TechBlogApiClient.listMyDrafts', () {
    test('type이 blog면 /v2/blogs/drafts/me 경로와 Authenticate 헤더를 사용한다', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, _, __) async {
          expect(options.method, 'GET');
          expect(
            options.uri,
            Uri.parse('$baseUrl/v2/blogs/drafts/me?page=0&size=20'),
          );
          expect(
            _headerValue(options.headers, 'Authenticate'),
            'Bearer access-token',
          );

          return _jsonResponse(
            _v2Envelope({
              'items': const [],
              'page': 0,
              'size': 20,
              'totalElements': 0,
              'totalPages': 0,
            }),
            200,
          );
        },
      );

      final page = await client.listMyBlogDrafts(
        accessToken: 'access-token',
      );

      expect(page.items, isEmpty);
    });
  });

  group('TechBlogApiClient.listMyScheduledPostsV2', () {
    test('예약 게시글 조회는 /scheduled/me 엔드포인트를 사용한다', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, _, __) async {
          expect(options.method, 'GET');
          expect(
            options.uri,
            Uri.parse('$baseUrl/v2/lectures/scheduled/me?page=1&size=10'),
          );

          return _jsonResponse(
            _v2Envelope({
              'items': const [],
              'page': 1,
              'size': 10,
              'totalElements': 0,
              'totalPages': 0,
            }),
            200,
          );
        },
      );

      final page = await client.listMyScheduledLectures(
        accessToken: 'access-token',
        page: 1,
        size: 10,
      );

      expect(page.page, 1);
      expect(page.size, 10);
    });
  });

  group('TechBlogApiClient.createPost', () {
    test('multipart post 파트에 scheduledPublishAt을 포함해 전송한다', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, body, _) async {
          expect(options.method, 'POST');
          expect(options.uri, Uri.parse('$baseUrl/v2/posts'));
          expect(
            _headerValue(options.headers, 'Authenticate'),
            'Bearer access-token',
          );

          final requestData = options.data;
          expect(requestData, isA<FormData>());
          final formData = requestData! as FormData;
          final postPart =
              formData.files.singleWhere((entry) => entry.key == 'post').value;
          expect(postPart.filename, 'post.json');
          expect(body,
              contains('"scheduledPublishAt":"2026-05-01T12:00:00.000Z"'));
          expect(body, contains('"status":"Scheduled"'));

          return _jsonResponse(
            _v2Envelope({
              'id': postId,
              'title': 'New Post',
              'author': {'id': 'owner-1'},
              'collaborators': const [],
              'status': 'Scheduled',
            }),
            200,
          );
        },
      );

      final created = await client.createPost(
        accessToken: 'access-token',
        post: CreatePostRequest(
          title: 'New Post',
          author: PostAuthor(id: 'owner-1'),
          status: PostStatus.scheduled,
          scheduledPublishAt: DateTime.parse('2026-05-01T12:00:00Z'),
        ),
      );

      expect(created.status, PostStatus.scheduled);
    });
  });

  group('TechBlogApiClient.patchPost', () {
    test('썸네일이 없으면 JSON PATCH 요청으로 전송한다', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, body, _) async {
          expect(options.method, 'PATCH');
          expect(options.uri, Uri.parse('$baseUrl/v2/posts/$postId'));
          expect(
            _headerValue(options.headers, 'Authenticate'),
            'Bearer access-token',
          );
          expect(_headerValue(options.headers, 'Content-Type'),
              'application/json');
          expect(jsonDecode(body), {
            'title': 'Updated title',
            'status': 'Published',
          });

          return _jsonResponse(
            _v2Envelope({
              'id': postId,
              'title': 'Updated title',
              'author': {'id': 'owner-1'},
              'collaborators': const [],
              'status': 'Published',
            }),
            200,
          );
        },
      );

      final patched = await client.patchPost(
        postId: postId,
        accessToken: 'access-token',
        post: PatchPostRequest(
          title: 'Updated title',
          status: PostStatus.published,
        ),
      );

      expect(patched.status, PostStatus.published);
    });
  });

  group('TechBlogApiClient.deletePost', () {
    test('삭제 응답의 deleted 값을 반환한다', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, _, __) async {
          expect(options.method, 'DELETE');
          expect(options.uri, Uri.parse('$baseUrl/v2/posts/$postId'));

          return _jsonResponse(
            _v2Envelope({'deleted': true}),
            200,
          );
        },
      );

      final deleted = await client.deletePost(
        postId: postId,
        accessToken: 'access-token',
      );

      expect(deleted, isTrue);
    });
  });

  group('TechBlogApiClient.addCollaborator', () {
    test('ownerId 없이 collaborator만 전송한다', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, body, _) async {
          expect(options.method, 'POST');
          expect(
            options.uri,
            Uri.parse('$baseUrl/v2/posts/$postId/collaborators'),
          );
          expect(
            _headerValue(options.headers, 'Content-Type'),
            'application/json',
          );
          expect(jsonDecode(body), {
            'collaborator': {'id': 'col-1', 'nickname': 'Col'},
          });

          return _jsonResponse(
            _v2Envelope({
              'id': postId,
              'title': 'Post',
              'author': {'id': 'owner-1'},
              'collaborators': [
                {'id': 'col-1', 'nickname': 'Col'},
              ],
              'status': 'Draft',
            }),
            200,
          );
        },
      );

      final updated = await client.addCollaborator(
        postId: postId,
        accessToken: 'access-token',
        request: AddCollaboratorRequest(
          ownerId: 'owner-1',
          collaborator: PostAuthor(id: 'col-1', nickname: 'Col'),
        ),
      );

      expect(updated.collaborators.single.id, 'col-1');
    });
  });

  group('TechBlogApiClient.uploadImage', () {
    test('multipart 업로드 후 메타데이터를 파싱한다', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, _, __) async {
          expect(options.method, 'POST');
          expect(options.uri, Uri.parse('$baseUrl/v2/posts/images'));
          expect(
            _headerValue(options.headers, 'Authenticate'),
            'Bearer access-token',
          );

          final requestData = options.data;
          expect(requestData, isA<FormData>());
          final formData = requestData! as FormData;
          expect(formData.files.single.key, 'file');

          return _jsonResponse(
            _v2Envelope({
              'url': 'https://cdn.example.com/images/key.png',
              'key': 'images/key.png',
              'contentType': 'image/png',
              'size': 3,
            }),
            200,
          );
        },
      );

      final uploaded = await client.uploadImage(
        accessToken: 'access-token',
        file: MultipartFile.fromBytes(<int>[1, 2, 3], filename: 'file.png'),
      );

      expect(uploaded.url, 'https://cdn.example.com/images/key.png');
      expect(uploaded.size, 3);
    });
  });
}

TechBlogApiClient _createClient({
  required String baseUrl,
  required Future<ResponseBody> Function(
    RequestOptions options,
    String body,
    Object? requestData,
  ) handler,
}) {
  final dio = Dio();
  dio.httpClientAdapter = _MockDioAdapter(handler);
  return TechBlogApiClient(baseUrl: baseUrl, dio: dio);
}

Map<String, dynamic> _v2Envelope(Object? data) {
  return {
    'success': true,
    'data': data,
    'error': null,
    'timestamp': '2026-05-01T12:00:00Z',
  };
}

ResponseBody _jsonResponse(Object? body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

String? _headerValue(Map<String, dynamic> headers, String name) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) {
      return entry.value?.toString();
    }
  }
  return null;
}

Matcher _isApiException({String? message, int? statusCode, String? code}) {
  return predicate<TechBlogApiException>((exception) {
    if (message != null && exception.message != message) {
      return false;
    }
    if (statusCode != null && exception.statusCode != statusCode) {
      return false;
    }
    if (code != null && exception.code != code) {
      return false;
    }
    return true;
  }, 'TechBlogApiException($message, $statusCode, $code)');
}

class _MockDioAdapter implements HttpClientAdapter {
  _MockDioAdapter(this._handler);

  final Future<ResponseBody> Function(
    RequestOptions options,
    String body,
    Object? requestData,
  ) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    final body = utf8.decode(bytes, allowMalformed: true);
    return _handler(options, body, options.data);
  }
}
