import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/widgets/error_view.dart';
import '../friends/friends_screen.dart';
import 'game_api.dart';
import 'models/duel.dart';
import 'screens/duel_play_screen.dart';
import 'widgets/friend_invite_sheet.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  DuelEligibility? _eligibility;
  List<DuelSummary>? _duels;
  bool _loading = true;
  String? _error;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final eligibility = await GameApi.instance.getEligibility();
      final duels = await GameApi.instance.getDuels();
      if (mounted) {
        setState(() {
          _eligibility = eligibility;
          _duels = duels;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _startDuelWithFriend(EligibleFriend friend) async {
    setState(() => _creating = true);
    try {
      final res = await GameApi.instance.createDuel(opponentId: friend.id);
      final duelId = res['id'] as int;
      if (!mounted) return;
      setState(() => _creating = false);
      await _openDuel(duelId);
      _loadData();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _startTrainingDuel() async {
    setState(() => _creating = true);
    try {
      final res = await GameApi.instance.createDuel(isBot: true);
      final duelId = res['id'] as int;
      if (!mounted) return;
      setState(() => _creating = false);
      await _openDuel(duelId);
      _loadData();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _openDuel(int duelId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DuelPlayScreen(duelId: duelId),
      ),
    );
    _loadData();
  }

  void _showInviteSheet() {
    final eligibility = _eligibility;
    if (eligibility == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FriendInviteSheet(
        friends: eligibility.friends,
        onSelect: _startDuelWithFriend,
        onOpenFriendsScreen: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FriendsScreen()),
          );
          _loadData();
        },
        onFriendAdded: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Który bliżej? · Pojedynki'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorView(
        message: _error!,
        onRetry: _loadData,
      );
    }

    final eligibility = _eligibility!;
    final duels = _duels ?? [];

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildStatusBanner(eligibility),
          const SizedBox(height: 12),
          _buildActionButtons(eligibility),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.history, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Twoje pojedynki',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (duels.isNotEmpty)
                Text(
                  '${duels.length}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (duels.isEmpty)
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Center(
                  child: Text(
                    'Brak rozegranych pojedynków.\nZaproś znajomego lub zagraj trening!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, height: 1.4),
                  ),
                ),
              ),
            )
          else
            ...duels.map(_buildDuelCard),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(DuelEligibility el) {
    final theme = Theme.of(context);
    final count = el.myVisitedCount;
    final minReq = el.minCardsRequired;
    final isReady = el.isEligible;

    return Card(
      elevation: 0,
      color: isReady
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              isReady ? Icons.check_circle_outline : Icons.info_outline,
              color: isReady
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isReady
                        ? 'Masz $count odblokowanych kart – talia gotowa!'
                        : 'Wymóg do gry ze znajomymi: min. $minReq kart',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isReady
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isReady
                        ? 'Wybierz znajomego i sprawdźcie, kto lepiej zna miasto!'
                        : 'Masz $count/$minReq kart. Odkryj jeszcze ${minReq - count} zabytków lub zagraj trening.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isReady
                          ? theme.colorScheme.onPrimaryContainer.withAlpha(200)
                          : theme.colorScheme.onSurfaceVariant.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(DuelEligibility el) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _creating ? null : _showInviteSheet,
            icon: _creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.person_add_alt_1),
            label: const Text('Zaproś znajomego do gry'),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _creating ? null : _startTrainingDuel,
            icon: const Icon(Icons.psychology_outlined),
            label: const Text('Trening solo (Przewodnik bot)'),
          ),
        ),
      ],
    );
  }

  Widget _buildDuelCard(DuelSummary duel) {
    final opponentName = duel.isCreator ? duel.opponentName : duel.creatorName;
    final isFinished = duel.isFinished;
    final hasPlayed = duel.hasPlayed;

    String statusText;
    Color statusColor;

    if (isFinished) {
      final myS = duel.myScore ?? 0;
      final oppS = duel.opponentScore ?? 0;
      if (myS > oppS) {
        statusText = 'Zwycięstwo ($myS : $oppS)';
        statusColor = Colors.green.shade700;
      } else if (myS < oppS) {
        statusText = 'Przegrana ($myS : $oppS)';
        statusColor = Colors.red.shade700;
      } else {
        statusText = 'Remis ($myS : $oppS)';
        statusColor = Colors.blue.shade700;
      }
    } else if (!hasPlayed) {
      statusText = 'Twoja tura';
      statusColor = Colors.teal.shade700;
    } else {
      statusText = 'Czeka na ruch rywala';
      statusColor = Colors.orange.shade800;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: duel.isBot
              ? Colors.teal.shade100
              : Colors.blue.shade100,
          child: Icon(
            duel.isBot ? Icons.psychology : Icons.person,
            color: Colors.black87,
          ),
        ),
        title: Text(
          opponentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$statusText · ${timeAgo(duel.createdAt)}',
          style: TextStyle(
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: FilledButton.tonal(
          onPressed: () => _openDuel(duel.id),
          child: Text(!hasPlayed ? 'Graj' : 'Podgląd'),
        ),
      ),
    );
  }
}
