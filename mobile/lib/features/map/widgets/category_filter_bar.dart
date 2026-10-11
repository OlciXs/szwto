import 'package:flutter/material.dart';

import '../../../core/models/monument_category.dart';

/// Przewijany pasek filtrów kategorii nad mapą. Pusty wybór = wszystkie.
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final category = categories[index];
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
