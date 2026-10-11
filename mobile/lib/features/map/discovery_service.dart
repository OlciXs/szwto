import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/location.dart';
import '../monuments/models/monument.dart';

/// Odkrywanie ukrytych perełek (Minor POI).
///
/// - zabytki główne (isMajor) są widoczne zawsze,
/// - perełka pojawia się, gdy gracz znajdzie się w promieniu
///   [AppConfig.discoveryRadiusMeters] – i zostaje odkryta na stałe,
/// - odwiedzone zabytki są widoczne zawsze.
/// Odkrycia zapisujemy lokalnie (osobno dla każdego konta).
class DiscoveryService {
  DiscoveryService._();
  static final DiscoveryService instance = DiscoveryService._();

  final Set<int> _discovered = {};

  /// Odkryte przed chwilą – marker odtwarza animację pojawienia się.
  final Set<int> _fresh = {};

  String? _storageKey;

  Future<void> load() async {
    final key = 'discovered_${ApiClient.instance.email ?? 'anon'}';
    if (key == _storageKey) return;
    _storageKey = key;
    final prefs = await SharedPreferences.getInstance();
    _discovered
      ..clear()
      ..addAll((prefs.getStringList(key) ?? const []).map(int.parse));
  }

  bool isVisible(Monument m) =>
      m.isMajor || m.visited || _discovered.contains(m.id);

  bool isFresh(int id) => _fresh.contains(id);

  int discoveredMinorCount(List<Monument> monuments) => monuments
      .where((m) => !m.isMajor && (m.visited || _discovered.contains(m.id)))
      .length;

  /// Liczba wciąż ukrytych perełek w promieniu [radius] – „Radar perełek” (nagroda za 5. poziom).
  int hiddenNearby(Position position, List<Monument> monuments, double radius) =>
      monuments
          .where((m) =>
              !isVisible(m) &&
              LocationService.distanceTo(position, m.latitude, m.longitude) <= radius)
          .length;

  /// Odkrywa perełki w zasięgu [position]. Zwraca nowo odkryte.
  /// [radius] rośnie z poziomem gracza (Perks.discoveryRadius).
  Future<List<Monument>> scan(
    Position position,
    List<Monument> monuments, {
    double radius = AppConfig.discoveryRadiusMeters,
  }) async {
    final found = monuments
        .where((m) =>
            !isVisible(m) &&
            LocationService.distanceTo(position, m.latitude, m.longitude) <= radius)
        .toList();
    if (found.isEmpty) return found;

    final ids = found.map((m) => m.id);
    _discovered.addAll(ids);
    _fresh.addAll(ids);
    // Animacja ma się odtworzyć tylko raz – potem marker jest zwykły
    Future.delayed(const Duration(seconds: 3), () => _fresh.removeAll(ids));

    final key = _storageKey;
    if (key != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        key,
        _discovered.map((id) => id.toString()).toList(),
      );
    }
    return found;
  }
}
