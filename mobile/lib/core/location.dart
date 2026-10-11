import 'package:geolocator/geolocator.dart';

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

  /// Dokładna, świeża pozycja – używana przy odznaczaniu zabytku.
  static Future<Position> freshPosition() async {
    final error = await ensureAccess();
    if (error != null) throw LocationException(error);

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      throw LocationException(
        'Nie udało się ustalić Twojej pozycji. Spróbuj ponownie.',
      );
    }
  }

  static double distanceTo(Position position, double lat, double lng) =>
      Geolocator.distanceBetween(position.latitude, position.longitude, lat, lng);
}
