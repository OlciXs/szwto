import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/demo_mode.dart';
import '../../core/location.dart';
import '../../core/models/monument_category.dart';
import '../../core/widgets/error_banner.dart';
import '../achievements/achievement_style.dart';
import '../achievements/achievements_api.dart';
import '../achievements/models/progression.dart';
import '../monuments/models/monument.dart';
import '../monuments/monument_detail_screen.dart';
import '../monuments/monuments_api.dart';
import '../monuments/widgets/monument_sheet.dart';
import '../monuments/widgets/visit_feedback.dart';
import 'discovery_service.dart';
import 'widgets/category_filter_bar.dart';
import 'widgets/monument_marker.dart';

/// Mapa zabytków – TOR A.
/// Zabytki główne są widoczne zawsze, ukryte perełki pojawiają się w zasięgu
/// [AppConfig.discoveryRadiusMeters] (DiscoveryService). W trybie demo długie
/// przytrzymanie mapy przenosi gracza w wybrane miejsce.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  final _discovery = DiscoveryService.instance;
  final _demo = DemoMode.instance;

  List<Monument> _monuments = [];

  /// Poziom gracza – zasięg perełek i radar to nagrody za poziom (tor B).
  Progression? _progression;
  Position? _gpsPosition;
  StreamSubscription<Position>? _positionSub;
  Set<MonumentCategory> _categoryFilter = {};

  bool _loading = true;
  String? _loadError;
  String? _locationError;
  bool _centeredOnUser = false;

  /// Pozycja gracza: „teleport” w trybie demo, inaczej GPS.
  Position? get _position => _demo.isActive ? _demo.position.value : _gpsPosition;

  double get _discoveryRadius =>
      _progression?.perks.discoveryRadius ?? AppConfig.discoveryRadiusMeters;

  static const _radarRadius = 1000.0;

  Future<void> _loadProgression() async {
    try {
      final progression = await AchievementsApi.instance.getProgression();
      if (!mounted) return;
      setState(() => _progression = progression);
      _scan(); // zasięg mógł wzrosnąć
    } on ApiException {
      // Bez poziomu działamy na domyślnym zasięgu.
    }
  }

  @override
  void initState() {
    super.initState();
    _demo.position.addListener(_onDemoPosition);
    _demo.enabled.addListener(_onDemoToggled);
    _init();
  }

  Future<void> _init() async {
    await _discovery.load();
    _loadProgression();
    await _loadMonuments();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _demo.position.removeListener(_onDemoPosition);
    _demo.enabled.removeListener(_onDemoToggled);
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ---------- Dane z backendu ----------

  Future<void> _loadMonuments() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final monuments = await MonumentsApi.instance.getMonuments();
      if (!mounted) return;
      setState(() => _monuments = monuments);
      _scan();
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Odkrywanie perełek ----------

  Future<void> _scan() async {
    final position = _position;
    if (position == null || _monuments.isEmpty) return;

    final result = await _discovery.scan(
      position,
      _monuments,
      radius: _discoveryRadius,
    );
    if (!mounted) return;
    if (result.changed) setState(() {}); // perełki pojawiły się / zniknęły

    final found = result.firstSeen;
    if (found.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amberAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                found.length == 1
                    ? 'Odkryto ukrytą perełkę: ${found.first.name}'
                    : 'Odkryto ukryte perełki w okolicy: ${found.length}',
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------- Lokalizacja ----------

  Future<void> _startLocationUpdates() async {
    final error = await LocationService.ensureAccess();
    if (!mounted) return;
    if (error != null) {
      setState(() => _locationError = error);
      return;
    }
    setState(() => _locationError = null);

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: LocationService.streamSettings,
      );
      _onGpsPosition(current);
    } catch (_) {
      // Pozycję i tak dostarczy strumień poniżej.
    }
    if (!mounted) return;

    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: LocationService.streamSettings,
    ).listen(_onGpsPosition, onError: (_) {});
  }

  void _onGpsPosition(Position position) {
    LocationService.remember(position);
    if (!mounted) return;
    setState(() {
      _gpsPosition = position;
      _locationError = null;
    });
    if (_demo.isActive) return;
    _scan();
    if (!_centeredOnUser) _centerOnUser();
  }

  void _onDemoPosition() {
    if (!mounted) return;
    setState(() {});
    _scan();
  }

  void _onDemoToggled() {
    if (!mounted) return;
    setState(() {});
    _scan();
  }

  void _onLongPress(TapPosition _, LatLng point) {
    if (!_demo.enabled.value) return;
    _demo.teleport(point.latitude, point.longitude);
  }

  void _centerOnUser() {
    final position = _position;
    if (position == null) return;
    try {
      _mapController.move(LatLng(position.latitude, position.longitude), 16);
      _centeredOnUser = true;
    } catch (_) {
      // Mapa nie jest jeszcze gotowa - spróbujemy przy następnej pozycji.
    }
  }

  void _onLocateButton() {
    if (_position == null) {
      _startLocationUpdates();
    } else {
      _centerOnUser();
    }
  }

  // ---------- Zabytek ----------

  Future<void> _openMonumentSheet(Monument monument) async {
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => MonumentSheet(monument: monument, position: _position),
    );
    if (!mounted) return;

    if (result is VisitResult) {
      setState(() {}); // pinezka zmienia kolor
      await showVisitFeedback(context, result);
      _loadProgression(); // nowy poziom = większy zasięg perełek
    } else if (result == MonumentSheetAction.openDetails) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              MonumentDetailScreen(monument: monument, position: _position),
        ),
      );
      if (!mounted) return;
      setState(() {}); // mógł zostać odwiedzony na ekranie szczegółów
      _loadProgression();
    }
  }

  // ---------- UI ----------

  List<MonumentCategory> get _presentCategories {
    final present = _monuments.map((m) => m.category).toSet();
    return MonumentCategory.values.where(present.contains).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final position = _position;
    final demoOn = _demo.enabled.value;

    final visible = _monuments
        .where(_discovery.isVisible)
        .where((m) =>
            _categoryFilter.isEmpty || _categoryFilter.contains(m.category))
        .toList()
      // główne rysujemy na wierzchu
      ..sort((a, b) => (a.isMajor ? 1 : 0) - (b.isMajor ? 1 : 0));

    final majors = _monuments.where((m) => m.isMajor).toList();
    final minorsTotal = _monuments.length - majors.length;
    final majorsVisited = majors.where((m) => m.visited).length;
    final minorsFound = _discovery.visitedMinorCount(_monuments);

    final progression = _progression;
    final radarCount = progression != null && progression.perks.radar && position != null
        ? _discovery.hiddenNearby(position, _monuments, _radarRadius)
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: progression == null
            ? null
            : Tooltip(
                message: 'Poziom ${progression.level} · ${progression.rankName}',
                child: Center(
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: rankColor(progression.rankIndex),
                    child: Text(
                      '${progression.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
        title: const Text('Odkrywca Zabytków'),
        actions: [
          if (_monuments.isNotEmpty)
            Tooltip(
              message: 'Odwiedzone: zabytki główne · ukryte perełki',
              child: Chip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 2),
                    Text('$majorsVisited/${majors.length}'),
                    const SizedBox(width: 10),
                    Icon(Icons.auto_awesome, size: 16, color: Colors.purple.shade400),
                    const SizedBox(width: 2),
                    Text('$minorsFound/$minorsTotal'),
                  ],
                ),
              ),
            ),
          IconButton(
            tooltip: 'Odśwież',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadMonuments,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(
                AppConfig.initialLatitude,
                AppConfig.initialLongitude,
              ),
              initialZoom: AppConfig.initialZoom,
              minZoom: 10,
              maxZoom: 19,
              onLongPress: _onLongPress,
              // na komputerze (np. prezentacja): prawy przycisk myszy
              onSecondaryTap: _onLongPress,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'pl.zabytki.zabytki_app',
              ),
              if (position != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(position.latitude, position.longitude),
                      radius: _discoveryRadius,
                      useRadiusInMeter: true,
                      color: theme.colorScheme.primary.withAlpha(20),
                      borderColor: theme.colorScheme.primary.withAlpha(90),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (final monument in visible)
                    buildMonumentMarker(
                      monument,
                      fresh: _discovery.isFresh(monument.id),
                      onTap: () => _openMonumentSheet(monument),
                    ),
                ],
              ),
              if (position != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(position.latitude, position.longitude),
                      width: 24,
                      height: 24,
                      // przepuszcza kliknięcia – stojąc na zabytku, nadal da się go otworzyć
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _demo.isActive ? Colors.deepPurple : Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(blurRadius: 6, color: Colors.black38),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© współtwórcy OpenStreetMap'),
                  TextSourceAttribution('Dane zabytków: Wikidata, Wikipedia'),
                ],
              ),
            ],
          ),
          if (_monuments.isNotEmpty)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: CategoryFilterBar(
                categories: _presentCategories,
                selected: _categoryFilter,
                onChanged: (value) => setState(() => _categoryFilter = value),
              ),
            ),
          if (radarCount != null && radarCount > 0)
            Positioned(
              top: 58,
              left: 12,
              child: Material(
                color: Colors.purple.shade50,
                elevation: 2,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.radar, size: 18, color: Colors.purple.shade400),
                      const SizedBox(width: 6),
                      Text('Radar: $radarCount ukrytych perełek w promieniu 1 km'),
                    ],
                  ),
                ),
              ),
            ),
          if (_loading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
          if (_loadError != null)
            Positioned(
              top: 60,
              left: 12,
              right: 12,
              child: ErrorBanner(
                icon: Icons.cloud_off,
                text: _loadError!,
                actionLabel: 'Spróbuj ponownie',
                onAction: _loadMonuments,
              ),
            ),
          if (demoOn)
            Positioned(
              bottom: 16,
              left: 12,
              right: 88,
              child: Material(
                color: Colors.deepPurple.shade50,
                elevation: 3,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app, color: Colors.deepPurple),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tryb demo: przytrzymaj palec na mapie (na komputerze: prawy przycisk myszy), aby się tam przenieść.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_locationError != null)
            Positioned(
              bottom: 16,
              left: 12,
              right: 88,
              child: ErrorBanner(
                icon: Icons.location_off,
                text: _locationError!,
                actionLabel: 'Spróbuj ponownie',
                onAction: _startLocationUpdates,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Moja pozycja',
        onPressed: _onLocateButton,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
