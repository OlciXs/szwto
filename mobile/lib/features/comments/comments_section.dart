import 'package:flutter/material.dart';

/// Mini forum przy zabytku (issue #6) – TOR D.
/// Ekran szczegółów osadza ten widżet; implementację podmieniamy tylko tutaj
/// (lista komentarzy + pole dodawania + klik w autora -> profil publiczny).
class CommentsSection extends StatelessWidget {
  const CommentsSection({super.key, required this.monumentId});

  final int monumentId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Komentarze graczy',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          color: theme.colorScheme.surfaceContainerLow,
          child: const ListTile(
            leading: Icon(Icons.forum_outlined),
            title: Text('Wkrótce'),
            subtitle: Text('Tu pojawią się opinie graczy, którzy tu byli.'),
          ),
        ),
      ],
    );
  }
}
