import 'package:flutter/material.dart';

import '../achievement_style.dart';
import '../models/achievement.dart';

/// Pokazuje po kolei: „Nowy poziom!” (jeśli był awans), potem nowe osiągnięcia.
Future<void> showRewards(BuildContext context, Rewards rewards) async {
  if (rewards.levelUp) {
    await _showAnimatedDialog(context, _LevelUpContent(rewards: rewards));
  }
  if (rewards.newAchievements.isNotEmpty && context.mounted) {
    await _showAnimatedDialog(
      context,
      _AchievementsContent(achievements: rewards.newAchievements),
    );
  }
}

Future<void> _showAnimatedDialog(BuildContext context, Widget content) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Zamknij',
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, __, ___) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: content,
          ),
        ),
      ),
    ),
    transitionBuilder: (_, animation, __, child) => ScaleTransition(
      scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _LevelUpContent extends StatelessWidget {
  const _LevelUpContent({required this.rewards});

  final Rewards rewards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nowy poziom!',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withAlpha(120), blurRadius: 24, spreadRadius: 4),
              ],
            ),
            child: Text(
              '${rewards.level}',
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (rewards.rank != null)
            Text(
              rewards.rankUp ? 'Nowa ranga: ${rewards.rank}' : rewards.rank!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: rewards.rankUp ? FontWeight.bold : null,
              ),
            ),
          if (rewards.newPerks.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final perk in rewards.newPerks)
              ListTile(
                dense: true,
                leading: Icon(Icons.lock_open, color: color),
                title: Text('Odblokowano: $perk'),
              ),
          ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Super!'),
          ),
        ],
      ),
    );
  }
}

class _AchievementsContent extends StatelessWidget {
  const _AchievementsContent({required this.achievements});

  final List<AchievementBadge> achievements;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 48, color: Colors.amber.shade700),
          const SizedBox(height: 8),
          Text(
            achievements.length == 1 ? 'Nowe osiągnięcie!' : 'Nowe osiągnięcia!',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final a in achievements) AchievementBadgeTile(badge: a),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Super!'),
          ),
        ],
      ),
    );
  }
}

/// Wiersz z odznaką: ikona w kolorze medalu, nazwa, opis, premia XP.
class AchievementBadgeTile extends StatelessWidget {
  const AchievementBadgeTile({super.key, required this.badge});

  final AchievementBadge badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = achievementColor(badge.tier, scheme);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(achievementIcon(badge.icon), color: Colors.white),
      ),
      title: Text(
        badge.tier == null ? badge.name : '${badge.name} (${badge.tier!.label})',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(badge.description),
      trailing: Text(
        '+${badge.xp} XP',
        style: TextStyle(
          color: Colors.orange.shade800,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
