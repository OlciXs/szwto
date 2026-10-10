import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/monument.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const _tokenKey = 'access_token';
  static const _emailKey = 'user_email';
  static const _apiUrlKey = 'api_base_url';
  static const _timeout = Duration(seconds: 15);

  String? _token;
  String? email;

  bool get isLoggedIn => _token != null;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ---------- Sesja ----------

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedApiUrl = prefs.getString(_apiUrlKey);
    if (savedApiUrl != null && savedApiUrl.isNotEmpty) {
      AppConfig.setApiBaseUrl(savedApiUrl);
    }
    _token = prefs.getString(_tokenKey);
    email = prefs.getString(_emailKey);
  }

  Future<void> setApiBaseUrl(String value) async {
    AppConfig.setApiBaseUrl(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlKey, AppConfig.apiBaseUrl);
  }

  Future<void> _saveSession(String token, String userEmail) async {
    _token = token;
    email = userEmail;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, userEmail);
  }

  Future<void> logout() async {
    _token = null;
    email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
  }

  // ---------- Auth ----------

  Future<void> register(String email, String password) =>
      _authenticate('/auth/register', email, password);

  Future<void> login(String email, String password) =>
      _authenticate('/auth/login', email, password);

  Future<void> _authenticate(
    String path,
    String email,
    String password,
  ) async {
    final response = await _send(
      () => http.post(
        _uri(path),
        headers: _headers,
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ),
    );
    final data = _decode(response) as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    await _saveSession(data['accessToken'] as String, user['email'] as String);
  }

  // ---------- Zabytki ----------

  Future<List<Monument>> getMonuments() async {
    final response = await _send(
      () => http.get(_uri('/monuments'), headers: _headers),
    );
    final data = _decode(response) as List<dynamic>;
    return data
        .map((item) => Monument.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<VisitResult> visitMonument(
    int monumentId,
    double latitude,
    double longitude,
  ) async {
    final response = await _send(
      () => http.post(
        _uri('/monuments/$monumentId/visit'),
        headers: _headers,
        body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
      ),
    );
    return VisitResult.fromJson(_decode(response) as Map<String, dynamic>);
  }

  // ---------- Pomocnicze ----------

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiException(0, 'Serwer nie odpowiada. Spróbuj ponownie.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        0,
        'Brak połączenia z serwerem (${AppConfig.apiBaseUrl}).',
      );
    }
  }

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    var message = 'Wystąpił błąd (${response.statusCode}).';
    if (body is Map<String, dynamic>) {
      final raw = body['message'];
      if (raw is String) {
        message = raw;
      } else if (raw is List) {
        message = raw.join('\n');
      }
    }
    if (response.statusCode == 401 && message == 'Unauthorized') {
      message = 'Sesja wygasła. Zaloguj się ponownie.';
    }
    throw ApiException(response.statusCode, message);
  }
}
