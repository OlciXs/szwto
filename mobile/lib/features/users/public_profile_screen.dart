import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/widgets/error_view.dart';
import '../achievements/achievement_style.dart';
import '../achievements/widgets/rewards_dialog.dart';
import '../friends/friend_actions.dart';
import '../friends/models/friend.dart';
import '../friends/widgets/friend_badge.dart';
import '../showcase/widgets/showcase_section.dart';
import 'models/public_profile.dart';
import 'users_api.dart';

/// Publiczny profil innego gracza (z rankingu, komentarzy) – bez e-maila.
class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key, required this.userId, this.initialName});

  final int userId;

  /// Nazwa do paska tytułu zanim dane się wczytają.
  final String? initialName;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  PublicProfile? _profile;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final profile = await UsersApi.instance.getProfile(widget.userId);
      if (mounted) setState(() => _profile = profile);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// Dodaj / akceptuj / anuluj / usuń – zależnie od obecnego statusu.
  Future<void> _friendAction(PublicProfile p) async {
    setState(() => _busy = true);
    FriendStatus? next;
    switch (p.friendStatus) {
      case FriendStatus.none:
        next = (await FriendActions.addByCode(context, p.friendCode))?.status;
      case FriendStatus.incoming:
        next = (await FriendActions.accept(context, p.id))?.status;
      case FriendStatus.outgoing:
        final ok = await FriendActions.remove(context, p.id,
            successMessage: 'Anulowano zaproszenie.');
        if (ok) next = FriendStatus.none;
      case FriendStatus.friends:
        final ok = await FriendActions.remove(context, p.id,
            successMessage: 'Usunięto ze znajomych.', confirmName: p.displayName);
        if (ok) next = FriendStatus.none;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (next != null) _profile = p.copyWith(friendStatus: next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      appBar: AppBar(title: Text(profile?.displayName ?? widget.initialName ?? 'Gracz')),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : profile == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(onRefresh: _load, child: _buildContent(profile)),
    );
  }

  Widget _buildContent(PublicProfile p) {
    final theme = Theme.of(context);
    final color = rankColor(p.rankIndex);
    final initials = p.displayName.isEmpty
        ? '?'
        : p.displayName.substring(0, p.displayName.length >= 2 ? 2 : 1).toUpperCase();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 4),
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: color.withAlpha(40),
              child: Text(
                initials,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                p.displayName,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (p.isFriend) const FriendBadge(),
          ],
        ),
        if (p.friendCode.isNotEmpty)
          Text(
            '#${p.friendCode}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 1.5),
          ),
        Text(
          '${p.rankName} · poziom ${p.level}${p.isMe ? ' · to Ty' : ''}',
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        Text(
          'W grze od ${formatDate(p.createdAt)}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        if (!p.isMe) ...[
          const SizedBox(height: 12),
          Center(child: _FriendButton(status: p.friendStatus, busy: _busy, onPressed: () => _friendAction(p))),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            _Stat(value: '${p.totalXp}', label: 'XP', color: Colors.orange.shade800),
            _Stat(value: '${p.visitedCount}', label: 'Odwiedzone', color: Colors.green.shade700),
            _Stat(
              value: '${p.achievementsUnlocked}/${p.achievementsTotal}',
              label: 'Osiągnięcia',
              color: Colors.amber.shade800,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ShowcaseSection(showcase: p.showcase),
        if (p.recentAchievements.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Ostatnie osiągnięcia',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  for (final badge in p.recentAchievements) AchievementBadgeTile(badge: badge),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Przycisk relacji: Dodaj / Zaproszenie wysłane / Akceptuj / Znajomi.
class _FriendButton extends StatelessWidget {
  const _FriendButton({required this.status, required this.busy, required this.onPressed});

  final FriendStatus status;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final onTap = busy ? null : onPressed;
    return switch (status) {
      FriendStatus.none => FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.person_add),
          label: const Text('Dodaj do znajomych'),
        ),
      FriendStatus.incoming => FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.how_to_reg),
          label: const Text('Akceptuj zaproszenie'),
        ),
      FriendStatus.outgoing => OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.schedule_send),
          label: const Text('Zaproszenie wysłane · anuluj'),
        ),
      FriendStatus.friends => OutlinedButton.icon(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(foregroundColor: FriendBadge.color),
          icon: const Icon(Icons.group),
          label: const Text('Znajomi · usuń'),
        ),
    };
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
