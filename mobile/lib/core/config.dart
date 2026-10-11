class AppConfig {
  /// Adres backendu. Domyślnie produkcja (Render); lokalnie:
  ///   flutter run -d chrome --dart-define=API_URL=http://localhost:3000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://szwto.onrender.com',
  );

  /// Startowy widok mapy – Rynek we Wrocławiu.
  static const double initialLatitude = 51.1100;
  static const double initialLongitude = 17.0320;
  static const double initialZoom = 14;

  /// Zasięg „skanowania” – ukryte perełki pojawiają się na mapie w tym promieniu.
  static const double discoveryRadiusMeters = 250;
}
