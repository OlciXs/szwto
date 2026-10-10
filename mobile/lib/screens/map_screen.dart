import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../config.dart';
import '../models/monument.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _streamSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );

  final _api = ApiService.instance;
  final _mapController = MapController();

  List<Monument> _monuments = [];
  Position? _position;
  StreamSubscription<Position>? _positionSub;

  bool _loading = true;
  String? _loadError;
  String? _locationError;
  bool _centeredOnUser = false;

  @override
  void initState() {
    super.initState();
    _loadMonuments();
    _startLocationUpdates();
  }

  @override
  void dispose() {
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
      final monuments = await _api.getMonuments();
      if (!mounted) return;
      setState(() => _monuments = monuments);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _logout();
        return;
      }
      if (mounted) setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // ---------- Lokalizacja ----------

  /// Zwraca komunikat błędu albo null, jeśli lokalizacja jest dostępna.
  Future<String?> _ensureLocationAccess() async {
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

  Future<void> _startLocationUpdates() async {
    final error = await _ensureLocationAccess();
    if (!mounted) return;
    if (error != null) {
      setState(() => _locationError = error);
      return;
    }
    setState(() => _locationError = null);

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: _streamSettings,
      );
      _onPosition(current);
    } catch (_) {
      // Pozycję i tak dostarczy strumień poniżej.
    }
    if (!mounted) return;

    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: _streamSettings,
    ).listen(_onPosition, onError: (_) {});
  }

  void _onPosition(Position position) {
    if (!mounted) return;
    setState(() {
      _position = position;
      _locationError = null;
    });
    if (!_centeredOnUser) _centerOnUser();
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

  Future<Position> _freshPosition() async {
    final error = await _ensureLocationAccess();
    if (error != null) throw ApiException(0, error);

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      throw ApiException(
        0,
        'Nie udało się ustalić Twojej pozycji. Spróbuj ponownie.',
      );
    }
  }

  // ---------- Odznaczanie zabytku ----------

  Future<VisitResult> _visitMonument(Monument monument) async {
    final position = await _freshPosition();
    final result = await _api.visitMonument(
      monument.id,
      position.latitude,
      position.longitude,
    );

    if (mounted) {
      setState(() {
        monument.visited = true;
        monument.visitedAt = result.visitedAt ?? DateTime.now();
        _position = position;
      });
    }
    return result;
  }

  Future<void> _openMonumentSheet(Monument monument) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MonumentSheet(
        monument: monument,
        position: _position,
        onVisit: _visitMonument,
      ),
    );

    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final visitedCount = _monuments.where((m) => m.visited).length;

    final monumentMarkers = <Marker>[
      for (final monument in _monuments)
        Marker(
          point: LatLng(monument.latitude, monument.longitude),
          width: 44,
          height: 44,
          // Dolny środek ikony (czubek pinezki) wskazuje dokładnie na punkt
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _openMonumentSheet(monument),
            child: Icon(
              Icons.location_on,
              size: 44,
              color:
                  monument.visited ? Colors.green.shade600 : Colors.grey.shade600,
            ),
          ),
        ),
    ];

    final position = _position;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Odkrywca Zabytków'),
        actions: [
          if (_monuments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                avatar: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 18,
                ),
                label: Text('$visitedCount / ${_monuments.length}'),
              ),
            ),
          IconButton(
            tooltip: 'Odśwież',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadMonuments,
          ),
          IconButton(
            tooltip: 'Wyloguj',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(52.0, 19.4), // środek Polski
              initialZoom: 6,
              minZoom: 4,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'pl.zabytki.zabytki_app',
              ),
              MarkerLayer(markers: monumentMarkers),
              if (position != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(position.latitude, position.longitude),
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(blurRadius: 6, color: Colors.black38),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© współtwórcy OpenStreetMap'),
                ],
              ),
            ],
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
              top: 12,
              left: 12,
              right: 12,
              child: _Banner(
                icon: Icons.cloud_off,
                text: _loadError!,
                actionLabel: 'Spróbuj ponownie',
                onAction: _loadMonuments,
              ),
            ),
          if (_locationError != null)
            Positioned(
              bottom: 16,
              left: 12,
              right: 88,
              child: _Banner(
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

// ---------------------------------------------------------------------------
// Panel dolny z informacjami o zabytku
// ---------------------------------------------------------------------------

class _MonumentSheet extends StatefulWidget {
  const _MonumentSheet({
    required this.monument,
    required this.position,
    required this.onVisit,
  });

  final Monument monument;
  final Position? position;
  final Future<VisitResult> Function(Monument monument) onVisit;

  @override
  State<_MonumentSheet> createState() => _MonumentSheetState();
}

class _MonumentSheetState extends State<_MonumentSheet> {
  bool _busy = false;
  String? _error;

  double? get _distanceMeters {
    final position = widget.position;
    if (position == null) return null;
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      widget.monument.latitude,
      widget.monument.longitude,
    );
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final result = await widget.onVisit(widget.monument);
      if (!mounted) return;
      Navigator.of(context).pop(result.message);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _busy = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Nieoczekiwany błąd. Spróbuj ponownie.';
          _busy = false;
        });
      }
    }
  }

  static String _formatDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.round()} m';
  }

  static String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monument = widget.monument;
    final distance = _distanceMeters;
    final inRange = distance != null && distance <= AppConfig.visitRadiusMeters;
    final radius = AppConfig.visitRadiusMeters.round();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    monument.name,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  monument.visited ? Icons.check_circle : Icons.circle_outlined,
                  color:
                      monument.visited ? Colors.green.shade600 : Colors.grey,
                ),
              ],
            ),
            if (monument.visited && monument.visitedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Odwiedzono: ${_formatDate(monument.visitedAt!)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.green.shade700),
              ),
            ],
            const SizedBox(height: 12),
            Text(monument.description, style: theme.textTheme.bodyMedium),
            if (!monument.visited) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    inRange ? Icons.near_me : Icons.directions_walk,
                    size: 18,
                    color: inRange ? Colors.green.shade700 : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      distance == null
                          ? 'Nie znamy jeszcze Twojej pozycji. Aby odznaczyć zabytek, podejdź na odległość maks. $radius m.'
                          : inRange
                              ? 'Jesteś na miejscu (${_formatDistance(distance)} od zabytku).'
                              : 'Jesteś ok. ${_formatDistance(distance)} od zabytku. Podejdź na maks. $radius m.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (monument.visited || _busy) ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(monument.visited ? Icons.check_circle : Icons.flag),
                label: Text(
                  monument.visited
                      ? 'Zabytek odwiedzony'
                      : 'Oznacz jako odwiedzony',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Baner z komunikatem o błędzie
// ---------------------------------------------------------------------------

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.errorContainer,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            Icon(icon, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
