import 'package:flutter/foundation.dart';

class AppConfig {
  /// Adres backendu można nadpisać przy uruchomieniu, np.:
  /// flutter run --dart-define=API_URL=http://192.168.0.15:3000
  static const String _apiUrlOverride = String.fromEnvironment('API_URL');

  static String _apiBaseUrl = _defaultApiBaseUrl;

  static String get apiBaseUrl => _apiBaseUrl;

  static String get _defaultApiBaseUrl {
    if (_apiUrlOverride.isNotEmpty) return _apiUrlOverride;

    // Emulator Androida widzi komputer-gospodarza pod adresem 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    // Symulator iOS, desktop i web.
    return 'http://localhost:3000';
  }

  static String normalizeApiBaseUrl(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException(
        'Adres musi mieć format http://IP:port, np. http://192.168.1.10:3000.',
      );
    }
    return trimmed.replaceFirst(RegExp(r'/+$'), '');
  }

  static void setApiBaseUrl(String value) {
    _apiBaseUrl = normalizeApiBaseUrl(value);
  }

  /// Promień (w metrach), w którym można odznaczyć zabytek.
  /// Ostateczną decyzję zawsze podejmuje backend.
  static const double visitRadiusMeters = 50;
}
