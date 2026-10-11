import 'package:flutter/material.dart';

import '../monuments/models/monument.dart';
import '../monuments/monument_detail_screen.dart';
import 'monument_card.dart';

/// Modal z powiększoną kartą i możliwością przejścia do szczegółów zabytku.
class CardPreviewDialog extends StatelessWidget {
  const CardPreviewDialog({super.key, required this.monument});

  final Monument monument;

  static void show(BuildContext context, Monument monument) {
    showDialog<void>(
      context: context,
      builder: (_) => CardPreviewDialog(monument: monument),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDiscovered = monument.visited;
    final theme = CardRarityTheme.forRarity(monument.rarity);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Karta kolekcjonerska w powiększeniu
              AspectRatio(
                aspectRatio: 0.68,
                child: MonumentCardWidget(monument: monument),
              ),

              const SizedBox(height: 16),

              // Przyciski akcji
              if (isDiscovered) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.borderColor,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        // Navigator pobieramy PRZED zamknięciem okna – po pop()
                        // kontekst okna jest już zamykany.
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MonumentDetailScreen(monument: monument),
                          ),
                        );
                      },
                      icon: const Icon(Icons.menu_book_rounded),
                      label: const Text(
                        'Zobacz opis i historię',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.orangeAccent),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'Odwiedź ten obiekt we Wrocławiu,\naby odblokować kartę!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
