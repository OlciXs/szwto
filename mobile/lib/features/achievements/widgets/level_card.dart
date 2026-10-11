import 'package:flutter/material.dart';

import '../achievement_style.dart';
import '../models/progression.dart';

/// Karta poziomu w profilu: poziom, ranga, pasek XP, następna nagroda.
class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.progression});

  final Progression progression;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = progression;
    final color = rankColor(p.rankIndex);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color,
                  child: Text(
                    '${p.level}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poziom ${p.level}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(p.rankName, style: TextStyle(color: color)),
                    ],
                  ),
                ),
                Text(
                  '${p.totalXp} XP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: p.progress,
                minHeight: 10,
                color: color,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${p.xpIntoLevel} / ${p.xpForLevel} XP do poziomu ${p.level + 1}',
              style: theme.textTheme.bodySmall,
            ),
            if (p.nextUnlockLabel != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Poziom ${p.nextUnlockLevel}: ${p.nextUnlockLabel}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
