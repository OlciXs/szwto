import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/widgets/error_view.dart';
import '../achievements/achievement_style.dart';
import '../friends/friends_screen.dart';
import '../friends/widgets/friend_badge.dart';
import '../users/models/public_profile.dart';
import '../users/public_profile_screen.dart';
import '../users/users_api.dart';

/// Ranking graczy po XP – tor D (wszyscy albo tylko znajomi). Klik w gracza otwiera jego profil.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  Leaderboard? _data;
  String? _error;
  bool _friendsOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await UsersApi.instance.getLeaderboard(friendsOnly: _friendsOnly);
      if (mounted) setState(() => _data = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _open(LeaderboardEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(userId: entry.id, initialName: entry.displayName),
      ),
    );
    if (mounted) _load(); // np. dodano znajomego na profilu
  }

  Future<void> _openFriends() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FriendsScreen()));
    if (mounted) _load();
  }

  void _setScope(bool friendsOnly) {
    if (friendsOnly == _friendsOnly) return;
    setState(() {
      _friendsOnly = friendsOnly;
      _data = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final me = data?.me;
    final meOutsideTop = me != null && !data!.entries.any((e) => e.isMe);

    return Scaffold(
      appBar: AppBar(
        title: Text(data == null ? 'Ranking' : 'Ranking · ${data.totalPlayers} graczy'),
        actions: [
          IconButton(icon: const Icon(Icons.group), onPressed: _openFriends, tooltip: 'Znajomi'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Odśwież'),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.public), label: Text('Wszyscy')),
                ButtonSegment(value: true, icon: Icon(Icons.group), label: Text('Znajomi')),
              ],
              selected: {_friendsOnly},
              onSelectionChanged: (s) => _setScope(s.first),
            ),
          ),
        ),
      ),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : data == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (_friendsOnly && data.totalPlayers <= 1)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Column(
                            children: [
                              const Text(
                                'Nie masz jeszcze znajomych – dodaj kogoś po kodzie gracza, żeby się ścigać.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed: _openFriends,
                                icon: const Icon(Icons.person_add),
                                label: const Text('Dodaj znajomego'),
                              ),
                            ],
                          ),
                        ),
                      for (final entry in data.entries)
                        _EntryTile(entry: entry, onTap: () => _open(entry)),
                      if (meOutsideTop) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Center(child: Icon(Icons.more_vert)),
                        ),
                        _EntryTile(entry: me, onTap: () => _open(me)),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onTap});

  final LeaderboardEntry entry;
  final VoidCallback onTap;

  static const _medals = [Color(0xFFE0A800), Color(0xFF9EA7B0), Color(0xFFB87333)];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final medal = entry.position <= 3 ? _medals[entry.position - 1] : null;
    final color = rankColor(entry.rankIndex);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      color: entry.isMe ? scheme.primaryContainer : null,
      child: ListTile(
        onTap: onTap,
        leading: SizedBox(
          width: 40,
          child: Center(
            child: medal != null
                ? Icon(Icons.emoji_events, color: medal, size: 30)
                : Text(
                    '${entry.position}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: color,
              child: Text(
                '${entry.level}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                entry.isMe ? '${entry.displayName} (Ty)' : entry.displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (entry.isFriend) const FriendBadge(),
          ],
        ),
        subtitle: Text('${entry.rankName} · ${entry.visitedCount} odwiedzonych'),
        trailing: Text(
          '${entry.totalXp} XP',
          style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
