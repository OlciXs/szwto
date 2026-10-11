import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../achievements/widgets/rewards_dialog.dart';
import '../../collection/widgets/monument_card.dart';
import '../models/showcase.dart';
import '../showcase_api.dart';
import 'monument_picker.dart';

/// Gablotka (#4): rząd 5 miejsc. [editable] – własny profil (dodaj / zmień / usuń).
class ShowcaseSection extends StatefulWidget {
  const ShowcaseSection({
    super.key,
    required this.showcase,
    this.editable = false,
    this.onChanged,
  });

  final Showcase showcase;
  final bool editable;

  /// Po zmianie gablotki (np. żeby odświeżyć profil po nowym osiągnięciu).
  final VoidCallback? onChanged;

  @override
  State<ShowcaseSection> createState() => _ShowcaseSectionState();
}

class _ShowcaseSectionState extends State<ShowcaseSection> {
  late Showcase _showcase = widget.showcase;
  bool _busy = false;

  @override
  void didUpdateWidget(covariant ShowcaseSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showcase != widget.showcase) _showcase = widget.showcase;
  }

  Future<void> _pick(ShowcaseSlot slot) async {
    final monumentId = await showMonumentPicker(context);
    if (monumentId == null || !mounted) return;
    await _run(() async {
      final (showcase, rewards) = await ShowcaseApi.instance.setSlot(slot.slot, monumentId);
      if (!mounted) return;
      setState(() => _showcase = showcase);
      if (!rewards.isEmpty) await showRewards(context, rewards);
    });
  }

  Future<void> _clear(ShowcaseSlot slot) async {
    await _run(() async {
      final showcase = await ShowcaseApi.instance.clearSlot(slot.slot);
      if (mounted) setState(() => _showcase = showcase);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      widget.onChanged?.call();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onFilledTap(ShowcaseSlot slot) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Zmień zabytek'),
              onTap: () => Navigator.of(context).pop('change'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Usuń z gablotki'),
              onTap: () => Navigator.of(context).pop('clear'),
            ),
          ],
        ),
      ),
    );
    if (action == 'change') await _pick(slot);
    if (action == 'clear') await _clear(slot);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showcase = _showcase;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gablotka',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${showcase.unlockedSlots}/${showcase.maxSlots} miejsc',
                  style: theme.textTheme.bodySmall,
                ),
                if (_busy) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: showcase.slots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => SizedBox(
                  width: 105,
                  child: _buildSlot(showcase.slots[i]),
                ),
              ),
            ),
            if (widget.editable && showcase.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Wystaw swoje najlepsze odwiedzone zabytki – zobaczą je inni gracze.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlot(ShowcaseSlot slot) {
    final monument = slot.monument;
    if (monument != null) {
      return MonumentCard(
        data: monument,
        onTap: widget.editable && !_busy ? () => _onFilledTap(slot) : null,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    if (slot.locked) {
      return _EmptySlot(
        icon: Icons.lock_outline,
        label: 'Poziom ${slot.unlockLevel}',
        color: scheme.onSurfaceVariant.withAlpha(120),
      );
    }
    return _EmptySlot(
      icon: widget.editable ? Icons.add : Icons.crop_square,
      label: widget.editable ? 'Dodaj' : 'Puste',
      color: scheme.primary,
      onTap: widget.editable && !_busy ? () => _pick(slot) : null,
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Material(
        color: color.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withAlpha(90), width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
