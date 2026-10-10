import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Wspólny klient HTTP + sesja. Endpointy poszczególnych funkcji są w
/// `features/<funkcja>/<funkcja>_api.dart` – nie dopisuj ich tutaj.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _tokenKey = 'access_token';
  static const _emailKey = 'user_email';
  static const _displayNameKey = 'user_display_name';
  /// Darmowy Render usypia serwer – pierwsze żądanie po przerwie trwa ~30–50 s.
  static const _timeout = Duration(seconds: 60);

  String? _token;
  String? email;
  String? displayName;

  /// Wywoływane, gdy sesja wygaśnie (401 przy zalogowanym użytkowniku).
  void Function()? onUnauthorized;

  bool get isLoggedIn => _token != null;

  // ---------- Sesja ----------

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    email = prefs.getString(_emailKey);
    displayName = prefs.getString(_displayNameKey);
  }

  Future<void> saveSession({
    required String token,
    required String email,
    required String displayName,
  }) async {
    _token = token;
    this.email = email;
    this.displayName = displayName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_displayNameKey, displayName);
  }

  Future<void> clearSession() async {
    _token = null;
    email = null;
    displayName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_displayNameKey);
  }

  // ---------- Żądania ----------

  Future<dynamic> get(String path) =>
      _send(() => http.get(_uri(path), headers: _headers));

  Future<dynamic> post(String path, [Object? body]) => _send(
        () => http.post(_uri(path), headers: _headers, body: _encode(body)),
      );

  Future<dynamic> put(String path, [Object? body]) => _send(
        () => http.put(_uri(path), headers: _headers, body: _encode(body)),
      );

  Future<dynamic> patch(String path, [Object? body]) => _send(
        () => http.patch(_uri(path), headers: _headers, body: _encode(body)),
      );

  Future<dynamic> delete(String path) =>
      _send(() => http.delete(_uri(path), headers: _headers));

  // ---------- Pomocnicze ----------

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  String? _encode(Object? body) => body == null ? null : jsonEncode(body);

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiException(
        0,
        'Serwer nie odpowiada (${AppConfig.apiBaseUrl}). Jeśli to Render – serwer mógł się usypiać, spróbuj ponownie za chwilę.',
      );
    } catch (_) {
      throw ApiException(
        0,
        'Brak połączenia z serwerem (${AppConfig.apiBaseUrl}).',
      );
    }
    return _decode(response);
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

    // Wygasły token – czyścimy sesję i wracamy do logowania.
    // (401 przy logowaniu złym hasłem nie ma tokenu, więc tu nie trafia.)
    if (response.statusCode == 401 && _token != null) {
      message = 'Sesja wygasła. Zaloguj się ponownie.';
      clearSession().then((_) => onUnauthorized?.call());
    }
    throw ApiException(response.statusCode, message);
  }
}
