import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/widgets/error_view.dart';
import '../achievements/achievement_style.dart';
import '../users/public_profile_screen.dart';
import 'friend_actions.dart';
import 'friends_api.dart';
import 'models/friend.dart';

/// Znajomi: mój kod, dodawanie po kodzie, zaproszenia i lista znajomych.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _codeController = TextEditingController();
  FriendsOverview? _data;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await FriendsApi.instance.getOverview();
      if (mounted) setState(() => _data = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _add() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _sending) return;
    setState(() => _sending = true);
    final result = await FriendActions.addByCode(context, code);
    if (!mounted) return;
    setState(() => _sending = false);
    if (result != null) {
      _codeController.clear();
      _load();
    }
  }

  Future<void> _accept(FriendUser user) async {
    if (await FriendActions.accept(context, user.id) != null) _load();
  }

  Future<void> _remove(FriendUser user, String message, {bool confirm = false}) async {
    final removed = await FriendActions.remove(
      context,
      user.id,
      successMessage: message,
      confirmName: confirm ? user.displayName : null,
    );
    if (removed) _load();
  }

  Future<void> _open(FriendUser user) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(userId: user.id, initialName: user.displayName),
      ),
    );
    if (mounted) _load(); // status mógł się zmienić na profilu
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: '#$code'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Skopiowano #$code – wyślij go znajomemu.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        title: Text(data == null ? 'Znajomi' : 'Znajomi · ${data.friends.length}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Odśwież'),
        ],
      ),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : data == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(onRefresh: _load, child: _buildContent(data)),
    );
  }

  Widget _buildContent(FriendsOverview data) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MyCodeCard(code: data.myCode, onCopy: () => _copyCode(data.myCode)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dodaj znajomego',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 7,
                        decoration: const InputDecoration(
                          hintText: 'np. K7Q2MX',
                          prefixText: '#',
                          counterText: '',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _sending ? null : _add,
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add),
                      label: const Text('Dodaj'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (data.incoming.isNotEmpty) ...[
          _SectionHeader('Zaproszenia do znajomych (${data.incoming.length})'),
          for (final user in data.incoming)
            _FriendTile(
              user: user,
              highlight: true,
              onTap: () => _open(user),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Odrzuć',
                    icon: const Icon(Icons.close),
                    onPressed: () => _remove(user, 'Odrzucono zaproszenie.'),
                  ),
                  IconButton.filled(
                    tooltip: 'Akceptuj',
                    icon: const Icon(Icons.check),
                    onPressed: () => _accept(user),
                  ),
                ],
              ),
            ),
        ],
        _SectionHeader('Twoi znajomi (${data.friends.length})'),
        if (data.friends.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Nie masz jeszcze znajomych – wymień się kodami i porównujcie postępy w rankingu.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        for (final user in data.friends)
          _FriendTile(
            user: user,
            onTap: () => _open(user),
            trailing: PopupMenuButton<String>(
              onSelected: (_) => _remove(user, 'Usunięto ze znajomych.', confirm: true),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'remove', child: Text('Usuń ze znajomych')),
              ],
            ),
          ),
        if (data.outgoing.isNotEmpty) ...[
          _SectionHeader('Wysłane zaproszenia (${data.outgoing.length})'),
          for (final user in data.outgoing)
            _FriendTile(
              user: user,
              onTap: () => _open(user),
              trailing: TextButton(
                onPressed: () => _remove(user, 'Anulowano zaproszenie.'),
                child: const Text('Anuluj'),
              ),
            ),
        ],
      ],
    );
  }
}

class _MyCodeCard extends StatelessWidget {
  const _MyCodeCard({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Twój kod gracza', style: theme.textTheme.labelLarge),
                  SelectableText(
                    '#$code',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Podaj go znajomemu – doda Cię po kodzie.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Kopiuj kod',
              icon: const Icon(Icons.copy),
              onPressed: onCopy,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.user,
    required this.onTap,
    required this.trailing,
    this.highlight = false,
  });

  final FriendUser user;
  final VoidCallback onTap;
  final Widget trailing;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = rankColor(user.rankIndex);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: highlight ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            '${user.level}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user.displayName,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${user.rankName} · ${user.totalXp} XP · ${user.visitedCount} odwiedzonych',
        ),
        trailing: trailing,
      ),
    );
  }
}
