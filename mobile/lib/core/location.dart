import 'package:geolocator/geolocator.dart';

import 'demo_mode.dart';

class LocationException implements Exception {
  final String message;

  LocationException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  static const streamSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );

  /// Pozycja świeża i dokładna – można ją wysłać bez pytania GPS ponownie.
  static const _freshFor = Duration(seconds: 15);
  static const _goodAccuracyMeters = 30.0;

  /// Awaryjnie akceptujemy starszą pozycję, gdy GPS nie zdąży odpowiedzieć.
  static const _fallbackFor = Duration(minutes: 2);

  static Position? _lastKnown;

  /// Mapa przekazuje tu każdą pozycję ze strumienia GPS.
  static void remember(Position position) => _lastKnown = position;

  /// Zwraca komunikat błędu albo null, jeśli lokalizacja jest dostępna.
  static Future<String?> ensureAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Włącz usługi lokalizacji (GPS) w telefonie.';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return 'Aplikacja potrzebuje zgody na lokalizację, aby odznaczać zabytki.';
    }
    if (permission == LocationPermission.deniedForever) {
      return 'Zgoda na lokalizację jest zablokowana. Zmień ją w ustawieniach aplikacji.';
    }
    return null;
  }

  /// Pozycja do odznaczenia zabytku – szybko:
  ///   1) tryb demo -> pozycja z „teleportu”,
  ///   2) świeża (<15 s) i dokładna (≤30 m) pozycja ze strumienia mapy -> od razu,
  ///   3) w przeciwnym razie pomiar GPS (wysoka dokładność, maks. 8 s),
  ///   4) awaryjnie ostatnia znana pozycja (<2 min).
  static Future<Position> positionForVisit() async {
    final demo = DemoMode.instance;
    if (demo.isActive) return demo.position.value!;

    final last = _lastKnown;
    if (last != null &&
        _age(last) < _freshFor &&
        last.accuracy <= _goodAccuracyMeters) {
      return last;
    }

    final error = await ensureAccess();
    if (error != null) throw LocationException(error);

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      remember(position);
      return position;
    } catch (_) {
      if (last != null && _age(last) < _fallbackFor) return last;
      throw LocationException(
        'Nie udało się ustalić Twojej pozycji. Spróbuj ponownie.',
      );
    }
  }

  static Duration _age(Position position) =>
      DateTime.now().difference(position.timestamp);

  static double distanceTo(Position position, double lat, double lng) =>
      Geolocator.distanceBetween(position.latitude, position.longitude, lat, lng);
}
