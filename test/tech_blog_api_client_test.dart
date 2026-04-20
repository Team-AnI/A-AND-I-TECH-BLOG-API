import 'dart:convert';
import 'dart:typed_data';

import 'package:aandi_tech_blog/aandi_tech_blog.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const baseUrl = 'https://api.example.com';

  group('TechBlogApiClient.listPosts', () {
    test('sends GET request and parses paged posts', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, ignoredBody, ignoredData) async {
          expect(options.method, 'GET');
          expect(options.uri, Uri.parse('$baseUrl/v2/posts?page=0&size=20'));
          expect(_headerValue(options.headers, 'accept'), 'application/json');

          return _jsonResponse({
            'items': [
              {
                'id': '9f35dd42-ff17-4e47-8f66-fbc6fce13b8a',
                'title': 'First post',
                'summary': 'Summary',
                'contentMarkdown': '# Hello',
                'thumbnailUrl': 'https://cdn.example.com/thumb.jpg',
                'author': {
                  'id': 'owner-1',
                  'nickname': 'Owner',
                  'profileImageUrl': 'https://cdn.example.com/owner.jpg',
                },
                'collaborators': [
                  {'id': 'col-1', 'nickname': 'Col', 'profileImageUrl': null},
                ],
                'status': 'Draft',
                'createdAt': '2026-03-09T10:00:00Z',
                'updatedAt': '2026-03-09T12:00:00Z',
              },
            ],
            'page': 0,
            'size': 20,
            'totalElements': 1,
            'totalPages': 1,
          }, 200);
        },
      );

      final page = await client.listPosts();

      expect(page.page, 0);
      expect(page.size, 20);
      expect(page.totalElements, 1);
      expect(page.totalPages, 1);
      expect(page.items, hasLength(1));
      expect(page.items.single.id, '9f35dd42-ff17-4e47-8f66-fbc6fce13b8a');
      expect(page.items.single.author.id, 'owner-1');
      expect(page.items.single.status, PostStatus.draft);
    });

    test('throws TechBlogApiException on invalid response', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (ignoredOptions, ignoredBody, ignoredData) async =>
            _jsonResponse({'items': {}}, 200),
      );

      await expectLater(
        client.listPosts(),
        throwsA(
          _isApiException(
            message: 'Invalid paged post response',
            statusCode: 200,
          ),
        ),
      );
    });
  });

  group('TechBlogApiClient.getPost', () {
    const postId = '9f35dd42-ff17-4e47-8f66-fbc6fce13b8a';

    test('sends GET request and parses post response', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, ignoredBody, ignoredData) async {
          expect(options.method, 'GET');
          expect(options.uri, Uri.parse('$baseUrl/v2/posts/$postId'));
          expect(_headerValue(options.headers, 'accept'), 'application/json');

          return _jsonResponse({
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
            'collaborators': [],
            'status': 'Published',
            'createdAt': '2026-03-09T10:00:00Z',
            'updatedAt': '2026-03-09T12:00:00Z',
          }, 200);
        },
      );

      final post = await client.getPost(postId: postId);

      expect(post.id, postId);
      expect(post.status, PostStatus.published);
      expect(post.author.id, 'owner-1');
    });

    test('throws TechBlogApiException with API error payload', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (ignoredOptions, ignoredBody, ignoredData) async {
          return _jsonResponse({
            'success': false,
            'error': {'message': '게시글을 찾을 수 없습니다.', 'code': 'NOT_FOUND'},
          }, 404);
        },
      );

      await expectLater(
        client.getPost(postId: postId),
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

  group('TechBlogApiClient.listDrafts', () {
    test('sends GET request and parses draft page', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, ignoredBody, ignoredData) async {
          expect(options.method, 'GET');
          expect(
            options.uri,
            Uri.parse('$baseUrl/v2/posts/drafts?page=0&size=20'),
          );

          return _jsonResponse({
            'items': [],
            'page': 0,
            'size': 20,
            'totalElements': 0,
            'totalPages': 0,
          }, 200);
        },
      );

      final page = await client.listDrafts();
      expect(page.page, 0);
      expect(page.items, isEmpty);
    });
  });

  group('TechBlogApiClient.listMyPosts', () {
    test('sends authorized GET request with status filter', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, ignoredBody, ignoredData) async {
          expect(options.method, 'GET');
          expect(
            options.uri,
            Uri.parse('$baseUrl/v2/posts/me?page=1&size=10&status=Published'),
          );
          expect(
            _headerValue(options.headers, 'authorization'),
            'Bearer access-token',
          );

          return _jsonResponse({
            'items': [],
            'page': 1,
            'size': 10,
            'totalElements': 0,
            'totalPages': 0,
          }, 200);
        },
      );

      final page = await client.listMyPosts(
        accessToken: 'access-token',
        page: 1,
        size: 10,
        status: PostStatus.published,
      );

      expect(page.page, 1);
      expect(page.size, 10);
    });
  });

  group('TechBlogApiClient.listMyDrafts', () {
    test('sends authorized GET request and parses draft page', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, ignoredBody, ignoredData) async {
          expect(options.method, 'GET');
          expect(
            options.uri,
            Uri.parse('$baseUrl/v2/posts/drafts/me?page=0&size=20'),
          );
          expect(
            _headerValue(options.headers, 'authorization'),
            'Bearer access-token',
          );

          return _jsonResponse({
            'items': [],
            'page': 0,
            'size': 20,
            'totalElements': 0,
            'totalPages': 0,
          }, 200);
        },
      );

      final page = await client.listMyDrafts(accessToken: 'access-token');
      expect(page.items, isEmpty);
    });
  });

  group('TechBlogApiClient.createPost', () {
    test('sends multipart POST and parses created post', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, body, ignoredData) async {
          expect(options.method, 'POST');
          expect(options.uri, Uri.parse('$baseUrl/v2/posts'));
          expect(_headerValue(options.headers, 'accept'), 'application/json');

          final requestData = options.data;
          expect(requestData, isA<FormData>());
          final formData = requestData! as FormData;
          expect(formData.files, hasLength(1));
          expect(formData.files.single.key, 'post');
          final postPart = formData.files.single.value;
          expect(postPart.filename, 'post.json');
          expect(postPart.contentType?.mimeType, 'application/json');
          expect(body, contains('name="post"'));
          expect(body, contains('application/json'));
          expect(body, contains('"title":"New Post"'));
          expect(body, contains('"id":"owner-1"'));
          expect(body, contains('"status":"Draft"'));

          return _jsonResponse({
            'id': '9f35dd42-ff17-4e47-8f66-fbc6fce13b8a',
            'title': 'New Post',
            'summary': 'Summary',
            'contentMarkdown': '# Hello',
            'thumbnailUrl': null,
            'author': {'id': 'owner-1'},
            'collaborators': [],
            'status': 'Draft',
            'createdAt': '2026-03-09T10:00:00Z',
            'updatedAt': '2026-03-09T12:00:00Z',
          }, 201);
        },
      );

      final created = await client.createPost(
        post: CreatePostRequest(
          title: 'New Post',
          author: PostAuthor(id: 'owner-1'),
          summary: 'Summary',
          contentMarkdown: '# Hello',
          status: PostStatus.draft,
        ),
      );

      expect(created.title, 'New Post');
      expect(created.author.id, 'owner-1');
      expect(created.status, PostStatus.draft);
    });

    test('throws TechBlogApiException with API error payload', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (ignoredOptions, ignoredBody, ignoredData) async {
          return _jsonResponse({
            'success': false,
            'error': {'message': 'Validation failed', 'code': 'BAD_REQUEST'},
          }, 400);
        },
      );

      await expectLater(
        client.createPost(
          post: CreatePostRequest(
            title: 'New Post',
            author: PostAuthor(id: 'owner-1'),
          ),
        ),
        throwsA(
          _isApiException(
            message: 'Validation failed',
            statusCode: 400,
            code: 'BAD_REQUEST',
          ),
        ),
      );
    });
  });

  group('TechBlogApiClient.patchPost', () {
    const postId = '9f35dd42-ff17-4e47-8f66-fbc6fce13b8a';

    test('sends JSON PATCH request when thumbnail is absent', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, body, _) async {
          expect(options.method, 'PATCH');
          expect(options.uri, Uri.parse('$baseUrl/v2/posts/$postId'));
          expect(
            _headerValue(options.headers, 'authorization'),
            'Bearer access-token',
          );
          expect(
            _headerValue(options.headers, 'content-type'),
            'application/json',
          );
          expect(jsonDecode(body), {
            'title': 'Updated title',
            'status': 'Published',
          });

          return _jsonResponse({
            'id': postId,
            'title': 'Updated title',
            'author': {'id': 'owner-1'},
            'collaborators': [],
            'status': 'Published',
          }, 200);
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

      expect(patched.title, 'Updated title');
      expect(patched.status, PostStatus.published);
    });

    test('sends multipart PATCH request when thumbnail is present', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, body, ignoredData) async {
          expect(options.method, 'PATCH');
          expect(options.uri, Uri.parse('$baseUrl/v2/posts/$postId'));

          final requestData = options.data;
          expect(requestData, isA<FormData>());
          final formData = requestData! as FormData;
          final postPart =
              formData.files.firstWhere((entry) => entry.key == 'post').value;
          expect(postPart.filename, 'post.json');
          expect(postPart.contentType?.mimeType, 'application/json');
          expect(formData.files.any((f) => f.key == 'thumbnail'), isTrue);
          expect(body, contains('name="post"'));
          expect(body, contains('application/json'));
          expect(body, contains('"title":"Updated with image"'));

          return _jsonResponse({
            'id': postId,
            'title': 'Updated with image',
            'author': {'id': 'owner-1'},
            'collaborators': [],
            'status': 'Draft',
          }, 200);
        },
      );

      final patched = await client.patchPost(
        postId: postId,
        accessToken: 'access-token',
        post: PatchPostRequest(title: 'Updated with image'),
        thumbnail: MultipartFile.fromBytes(<int>[
          1,
          2,
          3,
        ], filename: 'thumb.png'),
      );

      expect(patched.title, 'Updated with image');
    });
  });

  group('TechBlogApiClient.deletePost', () {
    const postId = '9f35dd42-ff17-4e47-8f66-fbc6fce13b8a';

    test('sends DELETE request and returns deletion result', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, ignoredBody, ignoredData) async {
          expect(options.method, 'DELETE');
          expect(options.uri, Uri.parse('$baseUrl/v2/posts/$postId'));

          return _jsonResponse({
            'success': true,
            'data': {'deleted': true},
          }, 200);
        },
      );

      final deleted = await client.deletePost(postId: postId);
      expect(deleted, isTrue);
    });

    test('throws TechBlogApiException with API error payload', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (ignoredOptions, ignoredBody, ignoredData) async {
          return _jsonResponse({
            'success': false,
            'error': {'message': '게시글을 찾을 수 없습니다.', 'code': 'NOT_FOUND'},
          }, 404);
        },
      );

      await expectLater(
        client.deletePost(postId: postId),
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

  group('TechBlogApiClient.addCollaborator', () {
    const postId = '9f35dd42-ff17-4e47-8f66-fbc6fce13b8a';

    test('sends authorized POST and parses updated post', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, body, _) async {
          expect(options.method, 'POST');
          expect(
            options.uri,
            Uri.parse('$baseUrl/v2/posts/$postId/collaborators'),
          );
          expect(
            _headerValue(options.headers, 'authorization'),
            'Bearer access-token',
          );
          expect(
            _headerValue(options.headers, 'content-type'),
            'application/json',
          );
          expect(jsonDecode(body), {
            'ownerId': 'owner-1',
            'collaborator': {'id': 'col-1', 'nickname': 'Col'},
          });

          return _jsonResponse({
            'id': postId,
            'title': 'Post',
            'author': {'id': 'owner-1'},
            'collaborators': [
              {'id': 'col-1', 'nickname': 'Col'},
            ],
            'status': 'Draft',
          }, 200);
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

      expect(updated.collaborators, hasLength(1));
      expect(updated.collaborators.single.id, 'col-1');
    });

    test('throws TechBlogApiException with API error payload', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (ignoredOptions, ignoredBody, ignoredData) async {
          return _jsonResponse({
            'success': false,
            'error': {'message': 'Forbidden', 'code': 'FORBIDDEN'},
          }, 403);
        },
      );

      await expectLater(
        client.addCollaborator(
          postId: postId,
          accessToken: 'access-token',
          request: AddCollaboratorRequest(
            collaborator: PostAuthor(id: 'col-1'),
          ),
        ),
        throwsA(
          _isApiException(
            message: 'Forbidden',
            statusCode: 403,
            code: 'FORBIDDEN',
          ),
        ),
      );
    });
  });

  group('TechBlogApiClient.uploadImage', () {
    test('sends multipart POST and parses uploaded image metadata', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (options, ignoredBody, ignoredData) async {
          expect(options.method, 'POST');
          expect(options.uri, Uri.parse('$baseUrl/v2/posts/images'));

          final requestData = options.data;
          expect(requestData, isA<FormData>());
          final formData = requestData! as FormData;
          expect(formData.files, hasLength(1));
          expect(formData.files.single.key, 'file');

          return _jsonResponse({
            'url': 'https://cdn.example.com/images/key.png',
            'key': 'images/key.png',
            'contentType': 'image/png',
            'size': 3,
          }, 200);
        },
      );

      final uploaded = await client.uploadImage(
        file: MultipartFile.fromBytes(<int>[1, 2, 3], filename: 'file.png'),
      );

      expect(uploaded.url, 'https://cdn.example.com/images/key.png');
      expect(uploaded.key, 'images/key.png');
      expect(uploaded.contentType, 'image/png');
      expect(uploaded.size, 3);
    });

    test('throws TechBlogApiException with API error payload', () async {
      final client = _createClient(
        baseUrl: baseUrl,
        handler: (ignoredOptions, ignoredBody, ignoredData) async {
          return _jsonResponse({
            'success': false,
            'error': {
              'message': 'Payload too large',
              'code': 'PAYLOAD_TOO_LARGE',
            },
          }, 413);
        },
      );

      await expectLater(
        client.uploadImage(
          file: MultipartFile.fromBytes(<int>[1, 2, 3], filename: 'file.png'),
        ),
        throwsA(
          _isApiException(
            message: 'Payload too large',
            statusCode: 413,
            code: 'PAYLOAD_TOO_LARGE',
          ),
        ),
      );
    });
  });
}

TechBlogApiClient _createClient({
  required String baseUrl,
  required Future<ResponseBody> Function(
    RequestOptions options,
    String body,
    Object? requestData,
  )
  handler,
}) {
  final dio = Dio();
  dio.httpClientAdapter = _MockDioAdapter(handler);
  return TechBlogApiClient(baseUrl: baseUrl, dio: dio);
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
  )
  _handler;

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
