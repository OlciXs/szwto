import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/widgets/error_view.dart';
import 'achievement_style.dart';
import 'achievements_api.dart';
import 'models/achievement.dart';

/// Wszystkie osiągnięcia pogrupowane, z paskami postępu (issue #5).
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  AchievementsList? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await AchievementsApi.instance.getAchievements();
      if (mounted) setState(() => _data = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          data == null
              ? 'Osiągnięcia'
              : 'Osiągnięcia ${data.unlockedCount}/${data.total}',
        ),
      ),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : data == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(onRefresh: _load, child: _buildList(data)),
    );
  }

  Widget _buildList(AchievementsList data) {
    final theme = Theme.of(context);
    final children = <Widget>[];
    String? currentGroup;
    for (final a in data.achievements) {
      if (a.group != currentGroup) {
        currentGroup = a.group;
        final inGroup = data.achievements.where((x) => x.group == a.group);
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            '${a.groupLabel}  ·  ${inGroup.where((x) => x.unlocked).length}/${inGroup.length}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ));
      }
      children.add(_AchievementTile(achievement: a));
    }
    children.add(const SizedBox(height: 24));
    return ListView(children: children);
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final a = achievement;
    final color = a.unlocked
        ? achievementColor(a.tier, scheme)
        : scheme.onSurfaceVariant.withAlpha(90);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: a.unlocked ? null : scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color,
              child: Icon(achievementIcon(a.icon), color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          a.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (a.tier != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          a.tier!.label,
                          style: TextStyle(
                            color: achievementColor(a.tier, scheme),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(a.description, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  if (a.unlocked)
                    Text(
                      'Odblokowano${a.unlockedAt != null ? ' ${formatDate(a.unlockedAt!)}' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade700),
                    )
                  else if (!a.secret)
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: a.ratio,
                              minHeight: 6,
                              backgroundColor: scheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${a.progress}/${a.target}', style: theme.textTheme.bodySmall),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '+${a.xp} XP',
              style: TextStyle(
                color: a.unlocked ? Colors.orange.shade800 : scheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
