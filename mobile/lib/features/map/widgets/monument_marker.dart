import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/rarity.dart';
import '../../monuments/models/monument.dart';

/// Pinezka zabytku: kolor = rzadkość, ikona = kategoria, zielona po odwiedzeniu.
Marker buildMonumentMarker(Monument monument, {required VoidCallback onTap}) {
  final size = monument.rarity == Rarity.legendary ? 34.0 : 26.0;
  final color = monument.visited ? Colors.green.shade600 : monument.rarity.color;

  return Marker(
    point: LatLng(monument.latitude, monument.longitude),
    width: size,
    height: size,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black26)],
        ),
        child: Icon(
          monument.visited ? Icons.check : monument.category.icon,
          size: size * 0.55,
          color: Colors.white,
        ),
      ),
    ),
  );
}
