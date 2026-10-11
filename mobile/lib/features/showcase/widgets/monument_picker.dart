import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../monuments/models/monument.dart';
import '../../monuments/monuments_api.dart';

/// Wybór zabytku do gablotki – tylko odwiedzone, najrzadsze na górze.
/// Zwraca id zabytku albo null.
Future<int?> showMonumentPicker(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _MonumentPicker(),
  );
}

class _MonumentPicker extends StatefulWidget {
  const _MonumentPicker();

  @override
  State<_MonumentPicker> createState() => _MonumentPickerState();
}

class _MonumentPickerState extends State<_MonumentPicker> {
  List<Monument>? _visited;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await MonumentsApi.instance.getMonuments();
      final visited = all.where((m) => m.visited).toList()
        ..sort((a, b) => b.rarity.index - a.rarity.index);
      if (mounted) setState(() => _visited = visited);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visited = _visited;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Text(
              'Wybierz zabytek do gablotki',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _error != null
                  ? Center(child: Text(_error!))
                  : visited == null
                      ? const Center(child: CircularProgressIndicator())
                      : visited.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Najpierw odwiedź jakiś zabytek – w gablotce można wystawić tylko odwiedzone.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: visited.length,
                              itemBuilder: (context, i) {
                                final m = visited[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: m.rarity.color,
                                    foregroundImage:
                                        m.thumbUrl != null ? NetworkImage(m.thumbUrl!) : null,
                                    child: Icon(m.category.icon, color: Colors.white),
                                  ),
                                  title: Text(m.name),
                                  subtitle: Text('${m.rarity.label} · ${m.subtitle}'),
                                  onTap: () => Navigator.of(context).pop(m.id),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
