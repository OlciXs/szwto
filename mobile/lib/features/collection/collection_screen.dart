import 'package:flutter/material.dart';

import '../../core/widgets/coming_soon.dart';

/// Kolekcja kart (issue #2) – TOR C.
/// Siatka kart: odwiedzone z ramką w kolorze rzadkości, nieodkryte jako „???”.
/// Dane: MonumentsApi.instance.getMonuments() (pola rarity, thumbUrl, visited).
/// Uwaga: Wikimedia zwraca 429 przy wielu obrazkach naraz – używaj GridView.builder
/// (leniwe ładowanie) i errorBuilder z ikoną kategorii jako zastępstwem.
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kolekcja')),
      body: const ComingSoon(
        icon: Icons.style_outlined,
        title: 'Kolekcja kart',
        description:
            'Każdy odwiedzony zabytek to karta – pospolita, rzadka, epicka lub legendarna.',
      ),
    );
  }
}
