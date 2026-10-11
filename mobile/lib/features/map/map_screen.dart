import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/location.dart';
import '../../core/widgets/error_banner.dart';
import '../monuments/models/monument.dart';
import '../monuments/monument_detail_screen.dart';
import '../monuments/monuments_api.dart';
import '../monuments/widgets/monument_sheet.dart';
import '../monuments/widgets/visit_feedback.dart';
import 'widgets/monument_marker.dart';

/// Mapa zabytków – TOR A (klastrowanie, filtry kategorii, itp. dopisujemy tutaj).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
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
      final monuments = await MonumentsApi.instance.getMonuments();
      if (!mounted) return;
      setState(() => _monuments = monuments);
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      _onPosition(current);
    } catch (_) {
      // Pozycję i tak dostarczy strumień poniżej.
    }
    if (!mounted) return;

    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: LocationService.streamSettings,
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
      showVisitFeedback(context, result);
    } else if (result == MonumentSheetAction.openDetails) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              MonumentDetailScreen(monument: monument, position: _position),
        ),
      );
      if (mounted) setState(() {}); // mógł zostać odwiedzony na ekranie szczegółów
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final visitedCount = _monuments.where((m) => m.visited).length;
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
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(
                AppConfig.initialLatitude,
                AppConfig.initialLongitude,
              ),
              initialZoom: AppConfig.initialZoom,
              minZoom: 10,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'pl.zabytki.zabytki_app',
              ),
              MarkerLayer(
                markers: [
                  for (final monument in _monuments)
                    buildMonumentMarker(
                      monument,
                      onTap: () => _openMonumentSheet(monument),
                    ),
                ],
              ),
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
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© współtwórcy OpenStreetMap'),
                  TextSourceAttribution('Dane zabytków: Wikidata'),
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
              child: ErrorBanner(
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
