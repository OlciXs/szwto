import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../models/duel.dart';

enum CardRole { player, opponent, center }

class DuelCardView extends StatelessWidget {
  final DuelCardItem card;
  final CardRole role;
  final String ownerName;
  final bool isSelected;
  final bool isSelectable;
  final bool isRevealed;
  final bool isCloser;
  final int? distanceMeters;
  final VoidCallback? onTap;

  const DuelCardView({
    super.key,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Color borderColor = Colors.grey.shade300;
    Color cardColor = scheme.surface;

    if (isRevealed) {
      if (isCloser) {
        borderColor = Colors.green.shade600;
        cardColor = Colors.green.shade50;
      } else {
        borderColor = Colors.grey.shade300;
      }
    } else if (isSelected) {
      borderColor = Colors.teal;
      cardColor = Colors.teal.shade50;
    }

    return Card(
      elevation: isSelected || (isRevealed && isCloser) ? 3 : 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: borderColor,
          width: isSelected || (isRevealed && isCloser) ? 2.5 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isSelectable ? onTap : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRoleHeader(context),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (card.thumbUrl != null && card.thumbUrl!.isNotEmpty)
                    Image.network(
                      card.thumbUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallback(context),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return _buildFallback(context);
                      },
                    )
                  else
                    _buildFallback(context),
                  if (isRevealed && distanceMeters != null)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCloser ? Colors.green.shade700 : Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${formatDistance(distanceMeters!.toDouble())}${isCloser ? " · BLIŻEJ!" : ""}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    card.category.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
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

  Widget _buildRoleHeader(BuildContext context) {
    final (label, icon, color) = switch (role) {
      CardRole.center => ('ŚRODEK', Icons.my_location, Colors.teal),
      CardRole.player => ('TWOJA KARTA', Icons.person, Colors.blue.shade700),
      CardRole.opponent => ('KARTA RYWALA', Icons.sports_kabaddi, Colors.orange.shade800),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: color.withAlpha(25),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              role == CardRole.center ? label : '$label ($ownerName)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(card.category.icon, size: 36, color: Colors.grey.shade400),
      ),
    );
  }
}
