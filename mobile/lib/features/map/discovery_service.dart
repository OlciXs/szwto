import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/location.dart';
import '../monuments/models/monument.dart';

/// Wynik skanowania okolicy.
class ScanResult {
  /// Perełki widziane pierwszy raz w historii – komunikat „Odkryto…”.
  final List<Monument> firstSeen;

  /// Czy zmienił się zestaw widocznych perełek (trzeba przerysować mapę).
  final bool changed;

  const ScanResult({required this.firstSeen, required this.changed});
}

/// Ukryte perełki (Minor POI):
/// - zabytki główne (isMajor) są widoczne zawsze,
/// - perełka jest widoczna TYLKO w zasięgu gracza (promień rośnie z poziomem);
///   po odejściu znika z mapy,
/// - na stałe zostaje dopiero po odwiedzeniu (odznaczeniu).
/// „Widziane” perełki zapisujemy lokalnie (osobno dla konta) tylko po to,
/// żeby komunikat „Odkryto…” nie powtarzał się przy każdym powrocie.
class DiscoveryService {
  DiscoveryService._();
  static final DiscoveryService instance = DiscoveryService._();

  /// Perełki aktualnie w zasięgu.
  final Set<int> _inRange = {};

  /// Perełki, które wcześniej były widziane (do komunikatów).
  final Set<int> _seen = {};

  /// Weszły w zasięg przy ostatnim skanie – marker odtwarza animację pojawienia się.
  final Set<int> _fresh = {};

  String? _storageKey;

  Future<void> load() async {
    final key = 'seen_gems_${ApiClient.instance.email ?? 'anon'}';
    if (key == _storageKey) return;
    _storageKey = key;
    _inRange.clear();
    final prefs = await SharedPreferences.getInstance();
    _seen
      ..clear()
      ..addAll((prefs.getStringList(key) ?? const []).map(int.parse));
  }

  bool isVisible(Monument m) => m.isMajor || m.visited || _inRange.contains(m.id);

  bool isFresh(int id) => _fresh.contains(id);

  /// Odwiedzone perełki – licznik na mapie.
  int visitedMinorCount(List<Monument> monuments) =>
      monuments.where((m) => !m.isMajor && m.visited).length;

  /// Liczba perełek (nieodwiedzonych) w promieniu [radius] poza zasięgiem
  /// skanowania – „Radar perełek” (nagroda za 5. poziom).
  int hiddenNearby(Position position, List<Monument> monuments, double radius) =>
      monuments
          .where((m) =>
              !isVisible(m) &&
              LocationService.distanceTo(position, m.latitude, m.longitude) <= radius)
          .length;

  /// Przelicza, które perełki są w zasięgu [position].
  Future<ScanResult> scan(
    Position position,
    List<Monument> monuments, {
    double radius = AppConfig.discoveryRadiusMeters,
  }) async {
    final nowInRange = monuments
        .where((m) =>
            !m.isMajor &&
            !m.visited &&
            LocationService.distanceTo(position, m.latitude, m.longitude) <= radius)
        .map((m) => m.id)
        .toSet();

    final entered = nowInRange.difference(_inRange);
    final changed = entered.isNotEmpty || _inRange.difference(nowInRange).isNotEmpty;
    _inRange
      ..clear()
      ..addAll(nowInRange);

    if (entered.isNotEmpty) {
      _fresh.addAll(entered);
      // Animacja ma się odtworzyć raz – potem marker jest zwykły
      Future.delayed(const Duration(seconds: 3), () => _fresh.removeAll(entered));
    }

    final firstSeenIds = entered.difference(_seen);
    final firstSeen = monuments.where((m) => firstSeenIds.contains(m.id)).toList();
    if (firstSeenIds.isNotEmpty) {
      _seen.addAll(firstSeenIds);
      final key = _storageKey;
      if (key != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(key, _seen.map((id) => id.toString()).toList());
      }
    }
    return ScanResult(firstSeen: firstSeen, changed: changed);
  }
}
