import 'package:flutter/material.dart';

/// Rzadkość zabytku (liczona przy imporcie danych – backend/scripts/import/enrich.ts).
/// Kolory używane na mapie, w kartach (#2) i w grze (#3).
enum Rarity {
  common('COMMON', 'Pospolity', Color(0xFF8D99A6)),
  rare('RARE', 'Rzadki', Color(0xFF1E88E5)),
  epic('EPIC', 'Epicki', Color(0xFF8E24AA)),
  legendary('LEGENDARY', 'Legendarny', Color(0xFFFFA000));

  const Rarity(this.apiValue, this.label, this.color);

  final String apiValue;
  final String label;
  final Color color;

  static Rarity fromApi(String? value) => Rarity.values.firstWhere(
        (r) => r.apiValue == value,
        orElse: () => Rarity.common,
      );
}
