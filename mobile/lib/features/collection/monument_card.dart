import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/models/rarity.dart';
import '../monuments/models/monument.dart';

/// Styl wizualny karty uzależniony w 100% od jej rzadkości.
class CardRarityTheme {
  final List<Color> backgroundGradient;
  final Color borderColor;
  final Color glowColor;
  final Color accentColor;
  final List<Color> ribbonGradient;
  final IconData rarityIcon;
  final String label;

  const CardRarityTheme({
    required this.backgroundGradient,
    required this.borderColor,
    required this.glowColor,
    required this.accentColor,
    required this.ribbonGradient,
    required this.rarityIcon,
    required this.label,
  });

  static CardRarityTheme forRarity(Rarity rarity) {
    switch (rarity) {
      case Rarity.legendary:
        return const CardRarityTheme(
          backgroundGradient: [
            Color(0xFF2B1D04),
            Color(0xFF4A3408),
            Color(0xFF1F1401),
          ],
          borderColor: Color(0xFFFFD54F),
          glowColor: Color(0xFFFFB300),
          accentColor: Color(0xFFFFE082),
          ribbonGradient: [
            Color(0xFFFFB300),
            Color(0xFFFF8F00),
          ],
          rarityIcon: Icons.workspace_premium_rounded,
          label: 'LEGENDARNA',
        );
      case Rarity.epic:
        return const CardRarityTheme(
          backgroundGradient: [
            Color(0xFF260D38),
            Color(0xFF4A156B),
            Color(0xFF180624),
          ],
          borderColor: Color(0xFFCE93D8),
          glowColor: Color(0xFFAB47BC),
          accentColor: Color(0xFFE1BEE7),
          ribbonGradient: [
            Color(0xFFAB47BC),
            Color(0xFF7B1FA2),
          ],
          rarityIcon: Icons.auto_awesome_rounded,
          label: 'EPICKA',
        );
      case Rarity.rare:
        return const CardRarityTheme(
          backgroundGradient: [
            Color(0xFF0A223D),
            Color(0xFF0D47A1),
            Color(0xFF051324),
          ],
          borderColor: Color(0xFF64B5F6),
          glowColor: Color(0xFF1E88E5),
          accentColor: Color(0xFF90CAF9),
          ribbonGradient: [
            Color(0xFF2196F3),
            Color(0xFF1565C0),
          ],
          rarityIcon: Icons.shield_rounded,
          label: 'RZADKA',
        );
      case Rarity.common:
        return const CardRarityTheme(
          backgroundGradient: [
            Color(0xFF22292E),
            Color(0xFF37474F),
            Color(0xFF191F24),
          ],
          borderColor: Color(0xFF90A4AE),
          glowColor: Color(0xFF78909C),
          accentColor: Color(0xFFCFD8DC),
          ribbonGradient: [
            Color(0xFF78909C),
            Color(0xFF546E7A),
          ],
          rarityIcon: Icons.lens_rounded,
          label: 'POSPOLITA',
        );
    }
  }
}

/// Kolekcjonerska karta zabytku (Trading Card) z oprawą w kolorze rzadkości.
class MonumentCardWidget extends StatelessWidget {
  const MonumentCardWidget({
    super.key,
    required this.monument,
    this.onTap,
  });

  final Monument monument;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDiscovered = monument.visited;
    final theme = CardRarityTheme.forRarity(monument.rarity);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isDiscovered
              ? LinearGradient(
                  colors: theme.backgroundGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFF1E2124), Color(0xFF141618)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: isDiscovered
                ? theme.borderColor
                : Colors.white.withAlpha(40),
            width: isDiscovered ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDiscovered
                  ? theme.glowColor.withAlpha(70)
                  : Colors.black.withAlpha(100),
              blurRadius: isDiscovered ? 10 : 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Górna belka z rzadkością i XP
              _buildTopBar(theme, isDiscovered),

              // Zdjęcie zabytku lub ikona kłódki dla nieodkrytych
              Expanded(
                child: _buildImageSection(theme, isDiscovered),
              ),

              // Dolna sekcja: Nazwa, kategoria i status
              _buildBottomInfo(theme, isDiscovered),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(CardRarityTheme theme, bool isDiscovered) {
    if (!isDiscovered) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        color: Colors.black.withAlpha(80),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, size: 14, color: Colors.white54),
            const SizedBox(width: 5),
            Text(
              'NIEODKRYTA',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.1,
                fontWeight: FontWeight.bold,
                color: Colors.white.withAlpha(160),
              ),
            ),
            const Spacer(),
            Text(
              '???',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white.withAlpha(120),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.ribbonGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            theme.rarityIcon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              theme.label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(100),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '+${monument.xp} XP',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(CardRarityTheme theme, bool isDiscovered) {
    if (!isDiscovered) {
      return Container(
        color: const Color(0xFF111315),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(15),
                  border: Border.all(color: Colors.white.withAlpha(30)),
                ),
                child: const Icon(
                  Icons.question_mark_rounded,
                  size: 32,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Odwiedź to miejsce\naby zdobyć kartę',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.white.withAlpha(110),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final thumb = monument.thumbUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumb != null && thumb.isNotEmpty)
          Image.network(
            thumb,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackImage(theme),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.black38,
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            },
          )
        else
          _buildFallbackImage(theme),

        // Winieta od góry i dołu
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withAlpha(170),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.55, 1.0],
              ),
            ),
          ),
        ),

        // Pływająca kategoria w prawym górnym rogu obrazka
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(160),
              shape: BoxShape.circle,
              border: Border.all(color: theme.borderColor.withAlpha(140)),
            ),
            child: Icon(
              monument.category.icon,
              size: 14,
              color: theme.accentColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackImage(CardRarityTheme theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.glowColor.withAlpha(40),
            Colors.black54,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          monument.category.icon,
          size: 44,
          color: theme.accentColor.withAlpha(180),
        ),
      ),
    );
  }

  Widget _buildBottomInfo(CardRarityTheme theme, bool isDiscovered) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      color: isDiscovered
          ? Colors.black.withAlpha(140)
          : const Color(0xFF16181B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isDiscovered ? monument.name : '??? Ukryty zabytek',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isDiscovered ? Colors.white : Colors.white60,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  isDiscovered ? monument.subtitle : monument.category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDiscovered ? theme.accentColor : Colors.white38,
                  ),
                ),
              ),
              if (isDiscovered) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.check_circle_rounded,
                  size: 13,
                  color: Colors.lightGreenAccent.shade400,
                ),
              ],
            ],
          ),
          if (isDiscovered && monument.visitedAt != null) ...[
            const SizedBox(height: 3),
            Text(
              'Odkryto: ${formatDate(monument.visitedAt!)}',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withAlpha(140),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
