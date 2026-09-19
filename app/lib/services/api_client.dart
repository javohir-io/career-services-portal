import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Thrown for any non-2xx API response. Carries the server's error
/// message (when available) so screens can show something useful.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Small wrapper around [http] that:
/// - Prefixes every request with the configured API base URL
/// - Attaches the stored JWT (if any) as a Bearer token
/// - Persists/clears the token in [SharedPreferences]
/// - Normalizes error handling into [ApiException]
///
/// Base URL is configurable at build/run time, e.g.:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
/// Defaults to localhost, which works for desktop/web/iOS-simulator.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Exposed so screens can build full URLs for server-relative paths
  /// like a job's `imageUrl` or a user's `profilePhotoUrl`
  /// (e.g. "/uploads/images/abc.png" -> "http://localhost:3000/uploads/images/abc.png").
  static String get baseUrl => _baseUrl;

  static const _tokenKey = 'auth_token';
  String? _cachedToken;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$cleanPath').replace(
      queryParameters:
          query?.map((k, v) => MapEntry(k, v?.toString())) ?? null,
    );
  }

  Future<String?> get token async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _headers({bool json = true}) async {
    final t = await token;
    return {
      if (json) 'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = (decoded is Map && decoded['error'] != null)
          ? decoded['error'].toString()
          : 'Request failed (${response.statusCode})';
      throw ApiException(response.statusCode, message);
    }
    return decoded;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final response =
        await http.get(_uri(path, query), headers: await _headers());
    return _decode(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final response = await http.post(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final response = await http.put(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  /// Multipart POST for endpoints that accept a file (e.g. resume
  /// upload). Uses raw [bytes] rather than a file path so this works
  /// on every platform — web `file_picker` results never expose a
  /// real disk path, only bytes.
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    required String fileFieldName,
    required List<int> bytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    final t = await token;
    if (t != null) request.headers['Authorization'] = 'Bearer $t';
    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes(fileFieldName, bytes, filename: fileName),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _decode(response);
  }
}
