import 'package:flutter/material.dart';

import '../../../core/models/monument_category.dart';

/// Pasek filtrów kategorii nad mapą. Pusty wybór = wszystkie.
/// Pierwszy przycisk „Filtry” otwiera panel ze wszystkimi kategoriami naraz
/// (na wąskim ekranie nie trzeba przewijać paska).
class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  /// Kategorie obecne w danych (w tej kolejności).
  final List<MonumentCategory> categories;
  final Set<MonumentCategory> selected;
  final ValueChanged<Set<MonumentCategory>> onChanged;

  Future<void> _openSheet(BuildContext context) async {
    final result = await showModalBottomSheet<Set<MonumentCategory>>(
      context: context,
      showDragHandle: true,
      builder: (_) => _FilterSheet(categories: categories, initial: selected),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ActionChip(
              avatar: const Icon(Icons.tune, size: 16),
              label: Text(selected.isEmpty ? 'Filtry' : 'Filtry (${selected.length})'),
              elevation: 2,
              onPressed: () => _openSheet(context),
            );
          }
          final category = categories[index - 1];
          final isSelected = selected.contains(category);
          return FilterChip(
            avatar: Icon(category.icon, size: 16),
            label: Text(category.label),
            selected: isSelected,
            showCheckmark: false,
            elevation: 2,
            onSelected: (value) {
              final next = {...selected};
              value ? next.add(category) : next.remove(category);
              onChanged(next);
            },
          );
        },
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.categories, required this.initial});

  final List<MonumentCategory> categories;
  final Set<MonumentCategory> initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Set<MonumentCategory> _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pokaż na mapie',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in widget.categories)
                  FilterChip(
                    avatar: Icon(category.icon, size: 16),
                    label: Text(category.label),
                    selected: _selected.contains(category),
                    showCheckmark: false,
                    onSelected: (value) => setState(() {
                      value ? _selected.add(category) : _selected.remove(category);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, <MonumentCategory>{}),
                  child: const Text('Pokaż wszystkie'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: const Text('Zastosuj'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
