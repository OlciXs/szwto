import 'package:flutter/material.dart';

import '../../core/widgets/coming_soon.dart';

/// Geoguessr 1v1 (issue #3) – TOR E.
/// Runda: zabytek na środku + dwa do wyboru – który jest bliżej środka?
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gra')),
      body: const ComingSoon(
        icon: Icons.sports_esports_outlined,
        title: 'Który bliżej?',
        description:
            'Zgadnij, który z dwóch zabytków leży bliżej tego na środku. Zagraj solo albo wyzwij znajomego.',
      ),
    );
  }
}
