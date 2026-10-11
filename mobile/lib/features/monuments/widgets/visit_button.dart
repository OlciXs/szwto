import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/api_client.dart';
import '../../../core/format.dart';
import '../../../core/location.dart';
import '../models/monument.dart';
import '../monuments_api.dart';

/// Podpowiedź o odległości + przycisk „Oznacz jako odwiedzony”.
/// Pobiera świeżą pozycję GPS, wysyła wizytę i oznacza [monument] jako odwiedzony.
class VisitButton extends StatefulWidget {
  const VisitButton({
    super.key,
    required this.monument,
    required this.onVisited,
    this.position,
  });

  final Monument monument;

  /// Ostatnia znana pozycja (tylko do podpowiedzi o odległości).
  final Position? position;
  final void Function(VisitResult result) onVisited;

  @override
  State<VisitButton> createState() => _VisitButtonState();
}

enum _Stage { idle, locating, sending }

class _VisitButtonState extends State<VisitButton> {
  _Stage _stage = _Stage.idle;
  String? _error;

  bool get _busy => _stage != _Stage.idle;

  Future<void> _submit() async {
    setState(() {
      _stage = _Stage.locating;
      _error = null;
    });

    try {
      final position = await LocationService.positionForVisit();
      if (mounted) setState(() => _stage = _Stage.sending);
      final result = await MonumentsApi.instance.visitMonument(
        widget.monument.id,
        position.latitude,
        position.longitude,
      );
      widget.monument.visited = true;
      widget.monument.visitedAt = result.visitedAt ?? DateTime.now();
      if (!mounted) return;
      setState(() => _stage = _Stage.idle);
      widget.onVisited(result);
    } on ApiException catch (e) {
      _fail(e.message);
    } on LocationException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Nieoczekiwany błąd. Spróbuj ponownie.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _stage = _Stage.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monument = widget.monument;
    final position = widget.position;
    final radius = monument.visitRadius;
    final distance = position == null
        ? null
        : LocationService.distanceTo(
            position,
            monument.latitude,
            monument.longitude,
          );
    final inRange = distance != null && distance <= radius;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!monument.visited) ...[
          Row(
            children: [
              Icon(
                inRange ? Icons.near_me : Icons.directions_walk,
                size: 18,
                color: inRange ? Colors.green.shade700 : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  distance == null
                      ? 'Aby odznaczyć zabytek, podejdź na odległość maks. $radius m.'
                      : inRange
                          ? 'Jesteś na miejscu (${formatDistance(distance)} od zabytku).'
                          : 'Jesteś ok. ${formatDistance(distance)} od zabytku. Podejdź na maks. $radius m.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: (monument.visited || _busy) ? null : _submit,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(monument.visited ? Icons.check_circle : Icons.flag),
          label: Text(switch (_stage) {
            _Stage.locating => 'Ustalam pozycję…',
            _Stage.sending => 'Wysyłam…',
            _Stage.idle => monument.visited
                ? 'Odwiedzono ${monument.visitedAt != null ? formatDate(monument.visitedAt!) : ''}'
                : 'Oznacz jako odwiedzony (+${monument.xp} XP)',
          }),
        ),
      ],
    );
  }
}
