import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Supplies the Firebase ID token sent as `Authorization: Bearer …`.
typedef ApiTokenProvider = Future<String?> Function();

/// Error returned by the backend as `{ "error": code, "message": … }`, or a
/// synthetic `http_<status>` code when the body is not JSON.
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// Thin JSON client for the Game Note backend. Every request carries the
/// current Firebase ID token; responses are decoded JSON (`null` for empty
/// bodies such as 204).
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    ApiTokenProvider? tokenProvider,
    String baseUrl = ApiConfig.baseUrl,
  }) : _http = httpClient ?? http.Client(),
       _tokenProvider = tokenProvider ?? _firebaseIdToken,
       _baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl;

  final http.Client _http;
  final ApiTokenProvider _tokenProvider;
  final String _baseUrl;

  // coverage:ignore-start
  static Future<String?> _firebaseIdToken() async =>
      FirebaseAuth.instance.currentUser?.getIdToken();
  // coverage:ignore-end

  Uri uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse('$_baseUrl$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: query);
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// Uploads one file as multipart field [field].
  Future<dynamic> putMultipart(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest('PUT', uri(path))
      ..headers.addAll(await _headers())
      ..files.add(
        http.MultipartFile.fromBytes(field, bytes, filename: filename),
      );
    final streamed = await _http.send(request);
    return _decode(await http.Response.fromStream(streamed));
  }

  /// Opens a long-lived GET (Server-Sent Events). Throws [ApiException] for
  /// a non-200 status; the caller owns the returned byte stream.
  Future<http.StreamedResponse> openEventStream(String path) async {
    final request = http.Request('GET', uri(path))
      ..headers.addAll(await _headers())
      ..headers['Accept'] = 'text/event-stream';
    final streamed = await _http.send(request);
    if (streamed.statusCode != 200) {
      final response = await http.Response.fromStream(streamed);
      _decode(response); // throws for non-2xx
      throw ApiException(
        statusCode: response.statusCode,
        code: 'unexpected_status',
        message: 'Expected an event stream',
      );
    }
    return streamed;
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await _tokenProvider();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final request = http.Request(method, uri(path, query))
      ..headers.addAll(await _headers(json: body != null));
    if (body != null) request.body = jsonEncode(body);
    final streamed = await _http.send(request);
    return _decode(await http.Response.fromStream(streamed));
  }

  dynamic _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes);
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      return text.isEmpty ? null : jsonDecode(text);
    }
    var code = 'http_$status';
    var message = text;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        code = decoded['error'] as String? ?? code;
        message = decoded['message'] as String? ?? message;
      }
    } on FormatException {
      // Not JSON (e.g. a proxy error page) — keep the raw text.
    }
    throw ApiException(statusCode: status, code: code, message: message);
  }
}
