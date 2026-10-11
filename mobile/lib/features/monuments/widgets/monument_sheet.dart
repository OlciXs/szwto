import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/monument.dart';
import 'monument_badges.dart';
import 'visit_button.dart';

enum MonumentSheetAction { openDetails }

/// Panel dolny po kliknięciu pinezki: skrót informacji + szybkie odznaczenie.
/// Zwraca (pop) [VisitResult] po odznaczeniu albo [MonumentSheetAction.openDetails].
class MonumentSheet extends StatelessWidget {
  const MonumentSheet({super.key, required this.monument, this.position});

  final Monument monument;
  final Position? position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (monument.thumbUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      monument.thumbUrl!,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monument.name,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(monument.subtitle, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MonumentBadges(monument: monument),
            const SizedBox(height: 20),
            VisitButton(
              monument: monument,
              position: position,
              onVisited: (result) => Navigator.of(context).pop(result),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Szczegóły i komentarze'),
              onPressed: () =>
                  Navigator.of(context).pop(MonumentSheetAction.openDetails),
            ),
          ],
        ),
      ),
    );
  }
}
