import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/models/monument_category.dart';
import '../../core/models/rarity.dart';
import '../monuments/models/monument.dart';
import '../monuments/monuments_api.dart';
import '../map/widgets/category_filter_bar.dart';
import 'card_preview_dialog.dart';
import 'monument_card.dart';

enum CollectionFilter { discovered, all, locked }

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  List<Monument>? _allMonuments;
  bool _loading = true;
  String? _error;

  CollectionFilter _filter = CollectionFilter.discovered;
  Rarity? _rarityFilter;
  final Set<MonumentCategory> _categoryFilter = {};
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await MonumentsApi.instance.getMonuments();
      if (mounted) {
        setState(() {
          _allMonuments = list;
          // Jeśli gracz nie ma jeszcze żadnych kart, domyślnie pokaż wszystkie
          final discoveredCount = list.where((m) => m.visited).length;
          if (discoveredCount == 0 && _filter == CollectionFilter.discovered) {
            _filter = CollectionFilter.all;
          }
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Błąd pobierania danych: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Monument> get _filteredMonuments {
    if (_allMonuments == null) return [];

    return _allMonuments!.where((m) {
      // Filtr stanu odkrycia
      switch (_filter) {
        case CollectionFilter.discovered:
          if (!m.visited) return false;
          break;
        case CollectionFilter.locked:
          if (m.visited) return false;
          break;
        case CollectionFilter.all:
          break;
      }

      // Filtr rzadkości
      if (_rarityFilter != null && m.rarity != _rarityFilter) {
        return false;
      }

      // Filtr kategorii; pusty wybór oznacza wszystkie kategorie.
      if (_categoryFilter.isNotEmpty && !_categoryFilter.contains(m.category)) {
        return false;
      }

      // Filtr wyszukiwarki (nieodkrytych nie szukamy po nazwie – karta ją ukrywa)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = m.visited && m.name.toLowerCase().contains(query);
        final matchCat = m.category.label.toLowerCase().contains(query);
        if (!matchName && !matchCat) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.style, size: 24),
            SizedBox(width: 8),
            Text('Karty kolekcjonerskie'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _allMonuments == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Tasowanie kart zabytków...'),
          ],
        ),
      );
    }

    if (_error != null && _allMonuments == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
      );
    }

    final total = _allMonuments?.length ?? 0;
    final discovered = _allMonuments?.where((m) => m.visited).length ?? 0;
    final filtered = _filteredMonuments;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Statystyki talii
          SliverToBoxAdapter(
            child: _buildHeaderStats(discovered, total),
          ),

          // Pasek wyszukiwania i filtry
          SliverToBoxAdapter(
            child: _buildFiltersSection(),
          ),

          // Licznik wyników
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Karty w widoku: ${filtered.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  if (_rarityFilter != null ||
                      _categoryFilter.isNotEmpty ||
                      _searchQuery.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        setState(() {
                          _rarityFilter = null;
                          _categoryFilter.clear();
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Reset filtrów', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),

          // Siatka kart
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _filter == CollectionFilter.discovered
                            ? Icons.style_outlined
                            : Icons.search_off_rounded,
                        size: 56,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _filter == CollectionFilter.discovered
                            ? 'Brak odkrytych kart'
                            : 'Nie znaleziono pasujących kart',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _filter == CollectionFilter.discovered
                            ? 'Odwiedzaj zabytki we Wrocławiu i odznaczaj je na mapie, aby powiększać swoją talię!'
                            : 'Zmień kryteria wyszukiwania lub filtry.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final crossAxisCount = width > 900
                      ? 5
                      : (width > 680 ? 4 : (width > 480 ? 3 : 2));

                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final monument = filtered[index];
                        return MonumentCardWidget(
                          monument: monument,
                          onTap: () async {
                            await CardPreviewDialog.show(context, monument);
                            // zabytek mógł zostać odznaczony na ekranie szczegółów
                            if (mounted) _loadData();
                          },
                        );
                      },
                      childCount: filtered.length,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(int discovered, int total) {
    final progress = total > 0 ? discovered / total : 0.0;
    final percent = (progress * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withAlpha(120),
            Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(180),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kolekcja kart Wrocławia',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Zdobyto $discovered z $total kart ($percent%)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.black12,
            ),
          ),
          const SizedBox(height: 14),

          // Pigułki rzadkości działające jako szybkie filtry
          Row(
            children: Rarity.values.map((r) {
              final countDiscovered = _allMonuments
                      ?.where((m) => m.rarity == r && m.visited)
                      .length ??
                  0;
              final countTotal =
                  _allMonuments?.where((m) => m.rarity == r).length ?? 0;
              final isSelected = _rarityFilter == r;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _rarityFilter = isSelected ? null : r;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? r.color.withAlpha(60)
                            : Colors.black.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? r.color
                              : Colors.white.withAlpha(30),
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            r.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: r.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$countDiscovered / $countTotal',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Segmented button dla odkrytych/wszystkich/nieodkrytych
          SegmentedButton<CollectionFilter>(
            segments: const [
              ButtonSegment(
                value: CollectionFilter.discovered,
                icon: Icon(Icons.check_circle_outline, size: 16),
                label: Text('Zdobyte'),
              ),
              ButtonSegment(
                value: CollectionFilter.all,
                icon: Icon(Icons.dashboard_outlined, size: 16),
                label: Text('Wszystkie'),
              ),
              ButtonSegment(
                value: CollectionFilter.locked,
                icon: Icon(Icons.lock_outline, size: 16),
                label: Text('Do odkrycia'),
              ),
            ],
            selected: {_filter},
            onSelectionChanged: (set) {
              setState(() => _filter = set.first);
            },
          ),
          const SizedBox(height: 8),

          CategoryFilterBar(
            categories: _availableCategories,
            selected: _categoryFilter,
            sheetTitle: 'Pokaż w kolekcji',
            onChanged: (categories) {
              setState(() {
                _categoryFilter
                  ..clear()
                  ..addAll(categories);
              });
            },
          ),
          const SizedBox(height: 8),

          // Wyszukiwarka
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Szukaj karty po nazwie lub typie...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              isDense: true,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val.trim());
            },
          ),
        ],
      ),
    );
  }

  List<MonumentCategory> get _availableCategories {
    final monuments = _allMonuments;
    if (monuments == null) return const [];

    final available = monuments.map((monument) => monument.category).toSet();
    return MonumentCategory.values
        .where(available.contains)
        .toList(growable: false);
  }
}
