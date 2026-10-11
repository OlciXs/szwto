import 'package:flutter/material.dart';

import '../models/monument_card_data.dart';

/// Karta zabytku: zdjęcie w ramce w kolorze rzadkości, nazwa i rzadkość.
/// Gablotka (tor D) i kolekcja kart (tor C).
class MonumentCard extends StatelessWidget {
  const MonumentCard({super.key, required this.data, this.onTap});

  final MonumentCardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rarity = data.rarity;
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Material(
        color: rarity.color,
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (data.thumbUrl != null)
                    Image.network(
                      data.thumbUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _Placeholder(data: data),
                    )
                  else
                    _Placeholder(data: data),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rarity.label,
                          style: TextStyle(
                            color: rarity.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.data});

  final MonumentCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: data.rarity.color.withAlpha(60),
      alignment: Alignment.center,
      child: Icon(data.category.icon, size: 40, color: Colors.white70),
    );
  }
}
