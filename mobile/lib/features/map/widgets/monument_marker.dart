import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../monuments/models/monument.dart';

/// Pinezka zabytku:
///  - kolor = rzadkość, ikona = kategoria, zielona z ptaszkiem po odwiedzeniu,
///  - zabytek główny: większy, z poświatą,
///  - świeżo odkryta perełka: animacja pojawienia się ([fresh]).
Marker buildMonumentMarker(
  Monument monument, {
  required VoidCallback onTap,
  bool fresh = false,
}) {
  final size = monument.isMajor ? 40.0 : 28.0;
  return Marker(
    key: ValueKey('monument-${monument.id}'),
    point: LatLng(monument.latitude, monument.longitude),
    width: size + 16, // miejsce na poświatę
    height: size + 16,
    child: GestureDetector(
      onTap: onTap,
      child: Center(
        child: fresh
            ? _PopIn(child: _MarkerDot(monument: monument, size: size, highlight: true))
            : _MarkerDot(monument: monument, size: size),
      ),
    ),
  );
}

class _MarkerDot extends StatelessWidget {
  const _MarkerDot({
    required this.monument,
    required this.size,
    this.highlight = false,
  });

  final Monument monument;
  final double size;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color =
        monument.visited ? Colors.green.shade600 : monument.rarity.color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: monument.isMajor ? 3 : 2),
        boxShadow: [
          const BoxShadow(blurRadius: 3, color: Colors.black26),
          if (monument.isMajor || highlight)
            BoxShadow(
              blurRadius: 12,
              spreadRadius: highlight ? 4 : 2,
              color: color.withAlpha(150),
            ),
        ],
      ),
      child: Icon(
        monument.visited ? Icons.check : monument.category.icon,
        size: size * 0.55,
        color: Colors.white,
      ),
    );
  }
}

/// Animacja odkrycia: pinezka „wyskakuje” z odbiciem.
class _PopIn extends StatefulWidget {
  const _PopIn({required this.child});

  final Widget child;

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _scale =
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
