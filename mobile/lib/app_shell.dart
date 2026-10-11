import 'package:flutter/material.dart';

import 'features/collection/collection_screen.dart';
import 'features/game/game_screen.dart';
import 'features/map/map_screen.dart';
import 'features/profile/profile_screen.dart';

/// Główna nawigacja aplikacji. Każda zakładka to osobna funkcja (folder w features/).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  /// Zmieniany przy każdym wejściu w zakładkę, żeby odświeżyć dane (np. po wizycie).
  int _collectionVersion = 0;
  int _profileVersion = 0;

  void _select(int index) {
    setState(() {
      if (index == 1) _collectionVersion++;
      if (index == 3) _profileVersion++;
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack trzyma mapę w pamięci – przełączanie nie przeładowuje jej.
      body: IndexedStack(
        index: _index,
        children: [
          const MapScreen(),
          CollectionScreen(key: ValueKey('collection-$_collectionVersion')),
          const GameScreen(),
          ProfileScreen(key: ValueKey('profile-$_profileVersion')),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Karty',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports),
            label: 'Gra',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
