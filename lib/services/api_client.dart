import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../models/auth_user.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient extends ChangeNotifier {
  ApiClient._();

  static final instance = ApiClient._();
  static const _tokenKey = 'lost_and_found_access_token';
  static const _secureStorage = FlutterSecureStorage();

  String? _token;
  AuthUser? _currentUser;

  bool get isAuthenticated => _token != null && _currentUser != null;
  AuthUser? get currentUser => _currentUser;

  Future<void> restoreSession() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return;
    try {
      _token = token;
      final response = await get('/auth/session');
      final data = _dataMap(response);
      _currentUser = AuthUser.fromMap(
        (data['user'] as Map?)?.cast<String, dynamic>() ?? data,
      );
      notifyListeners();
    } catch (_) {
      await logout();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await post(
      '/auth/login',
      {'email': email.trim(), 'password': password},
      authenticated: false,
    );
    await _acceptSession(response);
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await post(
      '/auth/register',
      {
        'full_name': fullName.trim(),
        'email': email.trim(),
        'password': password,
      },
      authenticated: false,
    );
    final data = _dataMap(response);
    final token = data['access_token'] as String? ?? data['token'] as String?;
    if (token == null || token.isEmpty) {
      return true;
    }
    await _acceptSession(response);
    return false;
  }

  Future<void> requestPasswordReset(String email) async {
    await post(
      '/auth/password-reset',
      {'email': email.trim()},
      authenticated: false,
    );
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await post('/auth/logout', const {});
      }
    } finally {
      _token = null;
      _currentUser = null;
      await _secureStorage.delete(key: _tokenKey);
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = _uri(path, query);
    final response = await http.get(uri, headers: _headers());
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) async {
    final response = await http.post(
      _uri(path),
      headers: _headers(authenticated: authenticated),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fileName,
    required List<int> bytes,
    required String itemId,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    final headers = _headers()..remove('Content-Type');
    request.headers.addAll(headers);
    request.fields['item_id'] = itemId;
    request.files.add(
      http.MultipartFile.fromBytes('image', bytes, filename: fileName),
    );
    final response = await request.send();
    return _decode(await http.Response.fromStream(response));
  }

  Future<void> _acceptSession(Map<String, dynamic> response) async {
    final data = _dataMap(response);
    final token = data['access_token'] as String? ?? data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const ApiException('The server did not return a valid session.');
    }
    _token = token;
    _currentUser = AuthUser.fromMap(
      (data['user'] as Map?)?.cast<String, dynamic>() ?? data,
    );
    await _secureStorage.write(key: _tokenKey, value: token);
    notifyListeners();
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
        : AppConfig.apiBaseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Map<String, String> _headers({bool authenticated = true}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (authenticated && _token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body = {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) body = decoded.cast<String, dynamic>();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body['message'] as String? ??
          body['error'] as String? ??
          'The request could not be completed.';
      throw ApiException(message, statusCode: response.statusCode);
    }
    return body;
  }

  static Map<String, dynamic> _dataMap(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map
        ? data.cast<String, dynamic>()
        : response;
  }
}