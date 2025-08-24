
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({required this.baseUrl, this.defaultHeaders = const {}, this.timeout = const Duration(seconds: 15)});

  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;

  Uri _u(String path, [Map<String, dynamic>? query]) => Uri.parse(baseUrl).replace(
        path: Uri.parse(baseUrl).path + path,
        queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
      );

  Future<http.Response> _safe(http.BaseRequest request) async {
    final client = http.Client();
    try {
      final streamed = await client.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed);
    } on SocketException {
      rethrow;
    } on HttpException {
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> getJson(String path, {Map<String, dynamic>? query, Map<String, String>? headers}) async {
    final req = http.Request('GET', _u(path, query));
    req.headers.addAll(defaultHeaders);
    if (headers != null) req.headers.addAll(headers);
    final res = await _safe(req);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw HttpException('GET $path failed: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body, {Map<String, String>? headers}) async {
    final req = http.Request('POST', _u(path));
    req.headers.addAll({
      ...defaultHeaders,
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    });
    req.body = jsonEncode(body);
    final res = await _safe(req);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw HttpException('POST $path failed: ${res.statusCode} ${res.body}');
  }
}
