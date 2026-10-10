import 'package:flutter/material.dart';

import '../models/monument.dart';

/// Znaczki: rzadkość, kategoria i XP. Używane w panelu, szczegółach i kartach.
class MonumentBadges extends StatelessWidget {
  const MonumentBadges({super.key, required this.monument});

  final Monument monument;

  @override
  Widget build(BuildContext context) {
    final rarity = monument.rarity;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _Badge(
          icon: Icons.auto_awesome,
          label: rarity.label,
          color: rarity.color,
          filled: true,
        ),
        _Badge(
          icon: monument.category.icon,
          label: monument.category.label,
          color: Theme.of(context).colorScheme.primary,
        ),
        _Badge(
          icon: Icons.star,
          label: '${monument.xp} XP',
          color: Colors.orange.shade800,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(filled ? 255 : 90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
