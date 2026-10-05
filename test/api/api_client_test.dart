import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pes_arena/api/api_client.dart';
import 'package:pes_arena/api/api_json.dart';

void main() {
  late List<http.BaseRequest> sent;

  ApiClient client(
    http.Response Function(http.Request) respond, {
    String? token = 'tok',
    String baseUrl = 'https://api.test/',
  }) {
    sent = [];
    return ApiClient(
      httpClient: MockClient((request) async {
        sent.add(request);
        return respond(request);
      }),
      tokenProvider: () async => token,
      baseUrl: baseUrl,
    );
  }

  group('ApiClient', () {
    test('GET sends bearer token, query and decodes JSON', () async {
      final api = client((_) => http.Response('{"ok":true}', 200));

      final json = await api.get('/v1/x', query: {'q': 'tai'});

      expect(json, {'ok': true});
      final request = sent.single as http.Request;
      expect(request.method, 'GET');
      expect(request.url.toString(), 'https://api.test/v1/x?q=tai');
      expect(request.headers['Authorization'], 'Bearer tok');
      expect(request.headers.containsKey('Content-Type'), isFalse);
    });

    test('omits Authorization when there is no signed-in user', () async {
      final api = client((_) => http.Response('[]', 200), token: null);

      await api.get('/v1/x', query: const {});

      expect(sent.single.headers.containsKey('Authorization'), isFalse);
      expect(sent.single.url.toString(), 'https://api.test/v1/x');
    });

    test(
      'POST/PATCH/PUT send JSON bodies; DELETE and 204 yield null',
      () async {
        final api = client((_) => http.Response('', 204));

        expect(await api.post('/a', body: {'x': 1}), isNull);
        expect(await api.patch('/b', body: {'y': 2}), isNull);
        expect(await api.put('/c', body: {'z': 3}), isNull);
        expect(await api.delete('/d'), isNull);
        expect(await api.post('/e'), isNull);

        final methods = sent.map((r) => r.method).toList();
        expect(methods, ['POST', 'PATCH', 'PUT', 'DELETE', 'POST']);
        final post = sent.first as http.Request;
        expect(post.headers['Content-Type'], startsWith('application/json'));
        expect(jsonDecode(post.body), {'x': 1});
        expect(sent.last.headers.containsKey('Content-Type'), isFalse);
      },
    );

    test('decodes UTF-8 bodies', () async {
      final api = client(
        (_) => http.Response.bytes(utf8.encode('{"name":"Tài"}'), 200),
      );

      expect(await api.get('/u'), {'name': 'Tài'});
    });

    test('maps backend error JSON to ApiException', () async {
      final api = client(
        (_) =>
            http.Response('{"error":"forbidden","message":"Owner only"}', 403),
      );

      final error = await api
          .get('/x')
          .then<Object?>((_) => null)
          .catchError((Object e) => e);

      expect(
        error,
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 403)
            .having((e) => e.code, 'code', 'forbidden')
            .having((e) => e.message, 'message', 'Owner only')
            .having((e) => e.isNotFound, 'isNotFound', isFalse),
      );
      expect(error.toString(), 'ApiException(403, forbidden): Owner only');
    });

    test(
      'falls back to http_<status> for non-JSON or partial errors',
      () async {
        var body = '<html>Bad gateway</html>';
        final api = client((_) => http.Response(body, 502));

        await expectLater(
          api.get('/x'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.code, 'code', 'http_502')
                .having((e) => e.message, 'message', body),
          ),
        );

        body = '{}';
        await expectLater(
          api.get('/x'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.code, 'code', 'http_502')
                .having((e) => e.message, 'message', '{}'),
          ),
        );

        body = '[1]';
        await expectLater(
          api.get('/x'),
          throwsA(
            isA<ApiException>().having((e) => e.code, 'code', 'http_502'),
          ),
        );
      },
    );

    test('isNotFound is true for 404', () {
      const e = ApiException(statusCode: 404, code: 'not_found', message: '');
      expect(e.isNotFound, isTrue);
    });

    test('putMultipart uploads the file field with auth', () async {
      final api = client((_) => http.Response('{"id":"u1"}', 200));

      final json = await api.putMultipart(
        '/v1/me/avatar',
        field: 'file',
        bytes: [1, 2, 3],
        filename: 'a.png',
      );

      expect(json, {'id': 'u1'});
      final request = sent.single as http.Request;
      expect(request.method, 'PUT');
      expect(request.headers['Authorization'], 'Bearer tok');
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      expect(request.body, contains('name="file"; filename="a.png"'));
    });

    test('works with a base URL that has no trailing slash', () {
      final api = ApiClient(
        httpClient: MockClient((_) async => http.Response('', 204)),
        tokenProvider: () async => null,
        baseUrl: 'https://api.test',
      );
      expect(api.uri('/v1/a').toString(), 'https://api.test/v1/a');
    });
  });

  group('openEventStream', () {
    ApiClient streaming(int status, String body) => ApiClient(
      httpClient: MockClient.streaming((request, _) async {
        sent = [request];
        return http.StreamedResponse(Stream.value(utf8.encode(body)), status);
      }),
      tokenProvider: () async => 'tok',
      baseUrl: 'https://api.test',
    );

    test('returns the open stream with SSE headers', () async {
      final response = await streaming(
        200,
        'event: x\n\n',
      ).openEventStream('/v1/leagues/l1/events');

      expect(sent.single.headers['Accept'], 'text/event-stream');
      expect(sent.single.headers['Authorization'], 'Bearer tok');
      expect(await utf8.decodeStream(response.stream), 'event: x\n\n');
    });

    test('throws ApiException for error statuses', () async {
      await expectLater(
        streaming(404, '{"error":"not_found"}').openEventStream('/e'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 's', 404)),
      );
    });

    test('rejects a non-200 success status', () async {
      await expectLater(
        streaming(204, '').openEventStream('/e'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'c', 'unexpected_status'),
        ),
      );
    });
  });

  group('api_json', () {
    test('parses and formats ISO dates', () {
      expect(
        parseApiDate('2026-01-02T03:04:05.006Z'),
        DateTime.utc(2026, 1, 2, 3, 4, 5, 6),
      );
      final local = DateTime(2026);
      expect(parseApiDate(local), same(local));
      expect(parseApiDate(''), isNull);
      expect(parseApiDate(42), isNull);
      expect(
        toApiDate(DateTime.utc(2026, 1, 2, 3, 4, 5, 6)),
        '2026-01-02T03:04:05.006Z',
      );
      expect(toApiDateOrNull(null), isNull);
      expect(toApiDateOrNull(DateTime.utc(2026)), '2026-01-01T00:00:00.000Z');
    });

    test('list helpers skip malformed entries', () {
      expect(apiMapList(null), isEmpty);
      expect(
        apiMapList([
          {'a': 1},
          'x',
        ]),
        [
          {'a': 1},
        ],
      );
      expect(apiStringList('x'), isEmpty);
      expect(apiStringList(['a', 1, 'b']), ['a', 'b']);
    });
  });
}
