import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tryb demo („teleport”): przytrzymanie palca na mapie ustawia pozycję gracza.
/// Pozwala pokazać odkrywanie perełek i odznaczanie bez chodzenia po mieście.
/// Włączany przełącznikiem w Profilu. Backend sprawdza odległość od wysłanej
/// pozycji, więc działa bez zmian po stronie serwera.
class DemoMode {
  DemoMode._();
  static final DemoMode instance = DemoMode._();

  static const _enabledKey = 'demo_mode_enabled';

  final enabled = ValueNotifier<bool>(false);

  /// Pozycja ustawiona długim przytrzymaniem na mapie (null = jeszcze nie ustawiona).
  final position = ValueNotifier<Position?>(null);

  bool get isActive => enabled.value && position.value != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled.value = prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    if (!value) position.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  void teleport(double latitude, double longitude) {
    position.value = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}
