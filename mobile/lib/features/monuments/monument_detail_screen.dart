import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api_client.dart';
import '../../core/external_link.dart';
import '../../core/widgets/error_view.dart';
import '../comments/comments_section.dart';
import 'models/monument.dart';
import 'monuments_api.dart';
import 'widgets/monument_badges.dart';
import 'widgets/visit_button.dart';
import 'widgets/visit_feedback.dart';

/// Ekran szczegółów zabytku: zdjęcie, opis (odblokowany po wizycie – #6),
/// odznaczanie oraz sekcja komentarzy (tor D).
class MonumentDetailScreen extends StatefulWidget {
  const MonumentDetailScreen({super.key, required this.monument, this.position});

  /// Obiekt z listy na mapie – po wizycie oznaczamy go jako odwiedzony.
  final Monument monument;
  final Position? position;

  @override
  State<MonumentDetailScreen> createState() => _MonumentDetailScreenState();
}

class _MonumentDetailScreenState extends State<MonumentDetailScreen> {
  MonumentDetails? _details;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final details = await MonumentsApi.instance.getMonument(widget.monument.id);
      if (mounted) setState(() => _details = details);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onVisited(VisitResult result) {
    showVisitFeedback(context, result);
    _load(); // odblokowany opis
  }

  @override
  Widget build(BuildContext context) {
    final details = _details;
    return Scaffold(
      body: _loading && details == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && details == null
              ? SafeArea(child: ErrorView(message: _error!, onRetry: _load))
              : _buildContent(context, details!),
    );
  }

  Widget _buildContent(BuildContext context, MonumentDetails details) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final image = details.image;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: image != null ? 260 : null,
          title: Text(widget.monument.name, overflow: TextOverflow.ellipsis),
          flexibleSpace: image == null
              ? null
              : FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        image.thumbUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: scheme.surfaceContainerHighest),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [Colors.black54, Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          sliver: SliverList.list(
            children: [
              Text(
                widget.monument.name,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(details.teaser, style: theme.textTheme.titleSmall),
              if (details.address != null) ...[
                const SizedBox(height: 2),
                Text(
                  details.address!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 12),
              MonumentBadges(monument: details.monument),
              const SizedBox(height: 8),
              Text(
                details.visitorsCount == 0
                    ? 'Nikt jeszcze tu nie dotarł – bądź pierwszy!'
                    : 'Odwiedziło graczy: ${details.visitorsCount}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (details.summary != null && details.descriptionLocked) ...[
                const SizedBox(height: 16),
                Text(
                  details.summary!,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 20),
              VisitButton(
                monument: widget.monument,
                position: widget.position,
                onVisited: _onVisited,
              ),
              const SizedBox(height: 24),
              Text(
                'Historia',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (details.descriptionLocked)
                Card(
                  color: scheme.surfaceContainerLow,
                  child: ListTile(
                    leading: Icon(Icons.lock_outline, color: scheme.primary),
                    title: const Text('Historia zablokowana'),
                    subtitle: Text(
                      'Podejdź na ${widget.monument.visitRadius} m i odznacz to miejsce, '
                      'aby poznać jego pełną historię.',
                    ),
                  ),
                )
              else ...[
                for (final paragraph in details.paragraphs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      paragraph,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                if (details.descriptionSource == 'wikipedia')
                  Text(
                    'Źródło: Wikipedia (CC BY-SA 4.0)',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (details.wikipediaUrl != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text('Czytaj na Wikipedii'),
                      onPressed: () => openExternalUrl(context, details.wikipediaUrl!),
                    ),
                  if (image != null)
                    TextButton.icon(
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const Text('Autor i licencja zdjęcia'),
                      onPressed: () => openExternalUrl(context, image.pageUrl),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              CommentsSection(monumentId: widget.monument.id),
            ],
          ),
        ),
      ],
    );
  }
}
