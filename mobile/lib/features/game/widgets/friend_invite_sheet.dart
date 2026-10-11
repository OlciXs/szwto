import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../friends/friend_actions.dart';
import '../../friends/friends_api.dart';
import '../models/duel.dart';

class FriendInviteSheet extends StatefulWidget {
  final List<EligibleFriend> friends;
  final ValueChanged<EligibleFriend> onSelect;
  final VoidCallback onOpenFriendsScreen;
  final VoidCallback? onFriendAdded;

  const FriendInviteSheet({
    super.key,
    required this.friends,
    required this.onSelect,
    required this.onOpenFriendsScreen,
    this.onFriendAdded,
  });

  @override
  State<FriendInviteSheet> createState() => _FriendInviteSheetState();
}

class _FriendInviteSheetState extends State<FriendInviteSheet> {
  final _codeController = TextEditingController();
  String? _myCode;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _loadMyCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadMyCode() async {
    try {
      final overview = await FriendsApi.instance.getOverview();
      if (mounted) setState(() => _myCode = overview.myCode);
    } catch (_) {}
  }

  Future<void> _addFriendByCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _adding) return;

    setState(() => _adding = true);
    final res = await FriendActions.addByCode(context, code);
    if (!mounted) return;
    setState(() => _adding = false);

    if (res != null) {
      _codeController.clear();
      widget.onFriendAdded?.call();
    }
  }

  void _copyMyCode() {
    if (_myCode == null) return;
    Clipboard.setData(ClipboardData(text: '#$_myCode'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Skopiowano kod #$_myCode – wyślij go znajomemu!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.sports_esports_outlined, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Zaproś znajomego do gry',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (_myCode != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_2, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Twój kod gracza: #$_myCode',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _copyMyCode,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Kopiuj'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      hintText: 'Wpisz kod znajomego (#K7Q2MX)',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _adding ? null : _addFriendByCode,
                  child: _adding
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Dodaj'),
                ),
              ],
            ),
            const Divider(height: 20),
            if (widget.friends.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Brak dodanych znajomych',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Wpisz kod znajomego powyżej, aby dodać go do listy.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.friends.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final f = widget.friends[index];
                    final isReady = f.isEligible;

                    return Card(
                      elevation: 0,
                      color: isReady ? scheme.surfaceContainerLow : scheme.surfaceContainerHighest,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isReady ? Colors.teal : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          child: Text(
                            f.displayName.isNotEmpty ? f.displayName[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          f.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          isReady
                              ? '${f.visitedCount} odblokowanych kart (Gotowy)'
                              : '${f.visitedCount}/10 kart (Wymaga min. 10)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isReady ? Colors.teal.shade800 : Colors.orange.shade800,
                          ),
                        ),
                        trailing: FilledButton(
                          onPressed: isReady
                              ? () {
                                  Navigator.of(context).pop();
                                  widget.onSelect(f);
                                }
                              : null,
                          child: const Text('Graj'),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
