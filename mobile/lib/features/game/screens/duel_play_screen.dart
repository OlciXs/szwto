import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/format.dart';
import '../../../core/models/rarity.dart';
import '../../../core/widgets/error_view.dart';
import '../game_api.dart';
import '../models/duel.dart';
import '../widgets/duel_card_view.dart';

// ─────────────────────────── helpers ────────────────────────────

Color _rarityColor(Rarity rarity) => rarity.color;

// ───────────────── 3-D flip card for the center monument ─────────

class _FlipCard extends StatefulWidget {
  final DuelCardItem card;
  final bool flipped; // false=front(photo), true=back(history)

  const _FlipCard({required this.card, required this.flipped});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.flipped && !old.flipped) {
      _ctrl.forward();
    } else if (!widget.flipped && old.flipped) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rc = _rarityColor(widget.card.rarity);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final angle = _anim.value * pi;
        final isFront = angle < pi / 2;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);

        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: isFront
              ? _buildFront(rc)
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: _buildBack(rc),
                ),
        );
      },
    );
  }

  // Przód – pełnoprawna karta kolekcjonerska
  Widget _buildFront(Color rc) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: rc, width: 3),
        boxShadow: [
          BoxShadow(color: rc.withAlpha(100), blurRadius: 20, spreadRadius: 2),
          BoxShadow(color: rc.withAlpha(40), blurRadius: 40, spreadRadius: 4),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── górna belka z nazwą ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [rc, Color.lerp(rc, Colors.black, 0.35)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.my_location_rounded,
                        size: 11, color: Colors.white70),
                    const SizedBox(width: 4),
                    const Text(
                      'KARTA ŚRODKOWA',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  widget.card.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          // ── zdjęcie ──
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.card.thumbUrl != null)
                  Image.network(
                    widget.card.thumbUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(rc),
                  )
                else
                  _placeholder(rc),
                // vignette overlay
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(80),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── dolna belka – kategoria + rarność ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: rc.withAlpha(60), width: 1)),
            ),
            child: Row(
              children: [
                Icon(widget.card.category.icon, size: 14, color: rc),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    widget.card.category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: rc,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: rc.withAlpha(18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: rc.withAlpha(80)),
                  ),
                  child: Text(
                    widget.card.rarity.label.toUpperCase(),
                    style: TextStyle(
                      color: rc,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tył – historia / ciekawostka
  Widget _buildBack(Color rc) {
    final fact = _factLines(widget.card);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Color.lerp(rc, Colors.black, 0.15)!,
            Color.lerp(rc, Colors.black, 0.45)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withAlpha(60), width: 2),
        boxShadow: [
          BoxShadow(color: rc.withAlpha(120), blurRadius: 22, spreadRadius: 2),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // decorative circle
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(12),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(10),
              ),
            ),
          ),
          // content
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // badge
                Row(
                  children: [
                    const Icon(Icons.history_edu_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 5),
                    const Text(
                      'CIEKAWOSTKA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // monument name – BIG
                Text(
                  widget.card.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                // divider
                Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.white.withAlpha(160),
                      Colors.transparent,
                    ]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                // fact text – bigger, readable
                Expanded(
                  child: Text(
                    fact,
                    overflow: TextOverflow.fade,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // date chip at bottom
                if (widget.card.builtLabel != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.white.withAlpha(80)),
                    ),
                    child: Text(
                      '📅 ${widget.card.builtLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _placeholder(Color rc) => Container(
        color: rc.withAlpha(20),
        child: Center(
          child: Icon(widget.card.category.icon,
              size: 40, color: rc.withAlpha(80)),
        ),
      );
}

/// Generuje krótką "ciekawostkę" na podstawie danych karty.
String _factLines(DuelCardItem c) {
  final buf = StringBuffer();
  buf.write('${c.category.label}.');
  if (c.rawType != null) {
    buf.write(' Typ obiektu: ${c.rawType}.');
  }
  if (c.builtLabel != null) {
    buf.write(' Pochodzi z okresu: ${c.builtLabel}.');
  }
  buf.write(
      ' Zabytek zlokalizowany we Wrocławiu – odwiedź go i odblokuj kartę w swojej kolekcji!');
  return buf.toString();
}

// ───────────────── Playing card widget ─────────────────────────

class _PlayingCard extends StatelessWidget {
  final DuelCardItem card;
  final CardRole role;
  final String ownerName;
  final bool isSelected;
  final bool isSelectable;
  final bool isRevealed;
  final bool isCloser;
  final int? distanceMeters;
  final VoidCallback? onTap;

  const _PlayingCard({
    required this.card,
    required this.role,
    required this.ownerName,
    this.isSelected = false,
    this.isSelectable = false,
    this.isRevealed = false,
    this.isCloser = false,
    this.distanceMeters,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rc = _rarityColor(card.rarity);

    // border colour logic
    final Color border;
    if (isRevealed && isCloser) {
      border = Colors.green.shade600;
    } else if (isSelected && !isRevealed) {
      border = Colors.orange.shade700;
    } else {
      border = rc.withAlpha(120);
    }

    final Color bg;
    if (isRevealed && isCloser) {
      bg = Colors.green.shade50;
    } else if (isSelected && !isRevealed) {
      bg = Colors.orange.shade50;
    } else {
      bg = Colors.white;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: isCloser || isSelected ? 3 : 1.5),
        boxShadow: [
          BoxShadow(
            color: (isCloser ? Colors.green : isSelected ? Colors.orange : rc)
                .withAlpha(isCloser || isSelected ? 100 : 40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isSelectable ? onTap : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _topBadge(rc),
            Expanded(child: _photo(rc)),
            _bottomInfo(rc),
          ],
        ),
      ),
    );
  }

  Widget _topBadge(Color rc) {
    final (label, icon) = switch (role) {
      CardRole.player => ('TWOJA', Icons.person),
      CardRole.opponent => ('RYWAL', Icons.sports_kabaddi),
      CardRole.center => ('ŚRODEK', Icons.my_location),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [rc, rc.withAlpha(180)],
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            role == CardRole.center ? label : '$label · $ownerName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _photo(Color rc) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (card.thumbUrl != null)
          Image.network(
            card.thumbUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(rc),
          )
        else
          _placeholder(rc),
        // gradient overlay at bottom
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withAlpha(120),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
          ),
        ),
        if (isRevealed && distanceMeters != null)
          Positioned(
            bottom: 5,
            left: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: isCloser ? Colors.green.shade700 : Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${isCloser ? "✓ " : ""}${formatDistance(distanceMeters!.toDouble())}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // selection ripple indicator (before reveal)
        if (isSelected && !isRevealed)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _bottomInfo(Color rc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 5, 7, 6),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          Text(
            card.category.label,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(Color rc) => Container(
        color: rc.withAlpha(15),
        child: Center(
          child: Icon(card.category.icon, size: 34, color: rc.withAlpha(80)),
        ),
      );
}

// ───────────────── Round score pill ─────────────────────────────

class _RoundIndicator extends StatelessWidget {
  final int total;
  final int current;
  final List<bool?> results; // null=not played, true=correct, false=wrong

  const _RoundIndicator(
      {required this.total,
      required this.current,
      required this.results});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        Color c;
        IconData? icon;
        if (i < results.length) {
          c = (results[i] == true) ? Colors.green.shade600 : Colors.red.shade500;
          icon = (results[i] == true) ? Icons.check : Icons.close;
        } else if (i == current) {
          c = Colors.orange.shade700;
          icon = null;
        } else {
          c = Colors.grey.shade300;
          icon = null;
        }
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == current ? 32 : 24,
          height: 24,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 13, color: Colors.white)
                : Text(
                    '${i + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
          ),
        );
      }),
    );
  }
}

// ───────────────── Main DuelPlayScreen ──────────────────────────

class DuelPlayScreen extends StatefulWidget {
  final int duelId;
  const DuelPlayScreen({super.key, required this.duelId});

  @override
  State<DuelPlayScreen> createState() => _DuelPlayScreenState();
}

class _DuelPlayScreenState extends State<DuelPlayScreen> {
  DuelDetail? _duel;
  bool _loading = true;
  String? _error;

  int _roundIdx = 0;
  final List<String> _answers = [];
  final List<bool> _roundResults = [];
  bool _revealed = false;
  bool _flipped = false; // center card flip

  bool _submitting = false;
  DuelAnswersResult? _result;

  @override
  void initState() {
    super.initState();
    _loadDuel();
  }

  Future<void> _loadDuel() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final duel = await GameApi.instance.getDuel(widget.duelId);
      if (mounted) {
        setState(() {
          _duel = duel;
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

  void _pick(String choice) {
    if (_revealed || _submitting) return;
    final round = _duel!.rounds[_roundIdx];
    final correct = choice == round.closer;
    setState(() {
      _answers.add(choice);
      _roundResults.add(correct);
      _revealed = true;
    });
    // Flip center card after 400 ms
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _flipped = true);
    });
  }

  Future<void> _advance() async {
    final duel = _duel!;
    if (_roundIdx < duel.rounds.length - 1) {
      setState(() {
        _roundIdx++;
        _revealed = false;
        _flipped = false;
      });
    } else {
      setState(() => _submitting = true);
      try {
        final res = await GameApi.instance.submitAnswers(duel.id, _answers);
        if (mounted) {
          setState(() {
            _result = res;
            _submitting = false;
          });
        }
      } on ApiException catch (e) {
        if (mounted) {
          setState(() {
            _error = e.message;
            _submitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pojedynek')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pojedynek')),
        body: ErrorView(message: _error!, onRetry: _loadDuel),
      );
    }

    final duel = _duel!;

    if (_result != null) return _resultScreen(_result!, duel);
    if (duel.hasPlayed) return _alreadyPlayedScreen(duel);

    final round = duel.rounds[_roundIdx];
    final isCreator = duel.isCreator;

    final myCard = isCreator ? round.creatorMonument : round.opponentMonument;
    final oppCard = isCreator ? round.opponentMonument : round.creatorMonument;
    final myKey = isCreator ? 'CREATOR' : 'OPPONENT';
    final oppKey = isCreator ? 'OPPONENT' : 'CREATOR';
    final myDist = isCreator
        ? round.creatorDistanceMeters
        : round.opponentDistanceMeters;
    final oppDist = isCreator
        ? round.opponentDistanceMeters
        : round.creatorDistanceMeters;

    final selected = _revealed ? _answers[_roundIdx] : null;
    final correct = _roundResults.isNotEmpty && _roundResults.last;

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Runda ${_roundIdx + 1} / ${duel.rounds.length}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RoundIndicator(
              total: duel.rounds.length,
              current: _roundIdx,
              results: _roundResults,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // ── Question banner ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_searching_rounded,
                        size: 18, color: scheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Który zabytek leży bliżej karty na środku?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Karty pionowo i dopasowane do wysokości jednego ekranu ──
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _PlayingCard(
                        card: myCard,
                        role: CardRole.player,
                        ownerName:
                            isCreator ? duel.creatorName : duel.opponentName,
                        isSelectable: !_revealed,
                        isSelected: selected == myKey,
                        isRevealed: _revealed,
                        isCloser: round.closer == myKey,
                        distanceMeters: _revealed ? myDist : null,
                        onTap: () => _pick(myKey),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: _FlipCard(
                        card: round.centerMonument,
                        flipped: _flipped,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: _PlayingCard(
                        card: oppCard,
                        role: CardRole.opponent,
                        ownerName:
                            isCreator ? duel.opponentName : duel.creatorName,
                        isSelectable: !_revealed,
                        isSelected: selected == oppKey,
                        isRevealed: _revealed,
                        isCloser: round.closer == oppKey,
                        distanceMeters: _revealed ? oppDist : null,
                        onTap: () => _pick(oppKey),
                      ),
                    ),
                  ],
                ),
              ),

              // ── hint label ──
              if (!_revealed)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Kliknij swoją lub rywala kartę',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _flipped ? '← Ciekawostka o karcie środkowej ↑' : 'Karta środkowa zaraz się obróci...',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),

              const SizedBox(height: 10),

              // ── Feedback + next button ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _revealed
                    ? Column(
                        key: const ValueKey('revealed'),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: correct
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: correct
                                      ? Colors.green.shade400
                                      : Colors.red.shade400),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  correct ? Icons.check_circle : Icons.cancel,
                                  color: correct
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    correct
                                        ? 'Świetnie! Dobry wybór! (+1 pkt)'
                                        : 'Pudło! Druga karta była bliżej.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: correct
                                          ? Colors.green.shade900
                                          : Colors.red.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _submitting ? null : _advance,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Icon(_roundIdx < duel.rounds.length - 1
                                      ? Icons.arrow_forward_rounded
                                      : Icons.emoji_events_rounded),
                              label: Text(
                                _submitting
                                    ? 'Zapisywanie...'
                                    : _roundIdx < duel.rounds.length - 1
                                        ? 'Następna runda'
                                        : 'Podsumowanie!',
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(
                        key: ValueKey('waiting'),
                        height: 0,
                      ),
              ),

              const SizedBox(height: 10),
              ],
            ),
          ),
        ),
    );
  }

  // ── Result screen ──────────────────────────────────────────────
  Widget _resultScreen(DuelAnswersResult r, DuelDetail duel) {
    final winner = r.winner;
    final (title, emoji, color) = switch (winner) {
      'YOU' => ('Zwycięstwo!', '🏆', Colors.amber.shade700),
      'OPPONENT' => ('Przegrana', '😔', Colors.red.shade600),
      'DRAW' => ('Remis!', '🤝', Colors.blue.shade700),
      _ => ('Runda zakończona!', '✅', Colors.teal),
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Text('Wynik pojedynku',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Trophy / result
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withAlpha(120), width: 3),
                  ),
                  child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 44)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: color)),
              ),
              Center(
                child: Text(
                  '${r.score} / ${r.totalRounds} pkt',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (r.opponentScore != null)
                Center(
                  child: Text(
                    'Rywal: ${r.opponentScore} pkt',
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ),
              const SizedBox(height: 20),

              // round recap
              const Text('PODSUMOWANIE RUND',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              ...r.roundResults.asMap().entries.map((e) {
                final rr = e.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  color: rr.isCorrect
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: rr.isCorrect
                            ? Colors.green.shade300
                            : Colors.red.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          rr.isCorrect ? Icons.check_circle : Icons.cancel,
                          color: rr.isCorrect
                              ? Colors.green.shade700
                              : Colors.red.shade600,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Runda ${rr.roundNumber}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              Text(
                                '📍 ${rr.centerMonument.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600),
                              ),
                              Text(
                                'Twoja: ${formatDistance(rr.creatorDistanceMeters.toDouble())} | Rywal: ${formatDistance(rr.opponentDistanceMeters.toDouble())}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Powrót do menu gry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _alreadyPlayedScreen(DuelDetail duel) {
    return Scaffold(
      appBar: AppBar(title: const Text('Podgląd')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 56, color: Colors.teal),
              const SizedBox(height: 12),
              const Text('Pojedynek rozegrany!',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Twój wynik: ${duel.myScore ?? 0} z ${duel.roundsCount}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Powrót')),
            ],
          ),
        ),
      ),
    );
  }
}
