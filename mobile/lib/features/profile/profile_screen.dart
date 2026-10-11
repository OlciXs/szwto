import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/demo_mode.dart';
import '../../core/format.dart';
import '../../core/models/monument_category.dart';
import '../../core/routes.dart';
import '../../core/widgets/error_view.dart';
import '../achievements/achievement_style.dart';
import '../achievements/achievements_screen.dart';
import '../achievements/widgets/level_card.dart';
import '../achievements/widgets/rewards_dialog.dart';
import '../friends/friends_screen.dart';
import '../monuments/monuments_api.dart';
import '../showcase/widgets/showcase_section.dart';
import '../users/users_api.dart';
import 'models/user_profile.dart';
import 'profile_api.dart';

/// Własny profil. Sekcje innych torów (XP/poziom – B, gablotka – D,
/// achievementy – B) dodajemy jako osobne widżety w liście poniżej.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      var profile = await ProfileApi.instance.getProfile();
      // Starszy backend nie zwraca jeszcze rozbicia kategorii. Uzupełniamy je
      // z listy zabytków, żeby sekcja profilu nadal działała po aktualizacji aplikacji.
      if (profile.categoryProgress.isEmpty) {
        final monuments = await MonumentsApi.instance.getMonuments();
        final totals = <MonumentCategory, int>{};
        final visited = <MonumentCategory, int>{};
        for (final monument in monuments) {
          totals[monument.category] = (totals[monument.category] ?? 0) + 1;
          if (monument.visited) {
            visited[monument.category] = (visited[monument.category] ?? 0) + 1;
          }
        }
        profile = profile.copyWithCategoryProgress(
          MonumentCategory.values
              .where(totals.containsKey)
              .map(
                (category) => CategoryProgress(
                  category: category,
                  visited: visited[category] ?? 0,
                  total: totals[category]!,
                ),
              )
              .toList(),
        );
      }
      if (!mounted) return;
      setState(() => _profile = profile);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Zmiana nazwy gracza (widocznej w rankingu, komentarzach i profilu publicznym).
  Future<void> _editDisplayName() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EditNameDialog(initialName: _profile?.displayName ?? ''),
    );
    if (saved == true) await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mój profil')),
      body: _loading && _profile == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadProfile)
              : _profile != null
                  ? _buildProfileContent(theme, colorScheme, _profile!)
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildProfileContent(
    ThemeData theme,
    ColorScheme colorScheme,
    UserProfile profile,
  ) {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(
            profile: profile,
            colorScheme: colorScheme,
            onEditName: _editDisplayName,
          ),
          const SizedBox(height: 24),
          _RankSelectorCard(profile: profile, onChanged: _loadProfile),
          if (profile.progression != null) ...[
            LevelCard(progression: profile.progression!),
            const SizedBox(height: 12),
          ],
          _AchievementsPreview(profile: profile, onChanged: _loadProfile),
          const SizedBox(height: 12),
          _FriendsCard(profile: profile, onChanged: _loadProfile),
          const SizedBox(height: 12),
          _StatsCard(profile: profile, colorScheme: colorScheme),
          const SizedBox(height: 12),
          _CategoryProgressCard(profile: profile),
          const SizedBox(height: 24),

          // ---------- Ostatnie odwiedziny ----------
          if (profile.recentVisits.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Ostatnio odwiedzone',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...profile.recentVisits
                .map((visit) => _RecentVisitTile(visit: visit)),
          ],

          if (profile.visitedCount == 0) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.explore_outlined,
                      size: 48,
                      color: colorScheme.primary.withAlpha(153),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Jeszcze nie odwiedziłeś żadnego zabytku',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Otwórz mapę i podejdź do pierwszego zabytku!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ---------- Gablotka (tor D) ----------
          if (profile.showcase != null) ...[
            const SizedBox(height: 24),
            ShowcaseSection(
              showcase: profile.showcase!,
              editable: true,
              onChanged: _loadProfile,
            ),
          ],

          const SizedBox(height: 24),
          const _DemoModeCard(),

          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: logoutAndShowLogin,
            icon: const Icon(Icons.logout),
            label: const Text('Wyloguj się'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error.withAlpha(128)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nagłówek profilu (awatar + nazwa gracza + e-mail)
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.colorScheme,
    required this.onEditName,
  });

  final UserProfile profile;
  final ColorScheme colorScheme;
  final VoidCallback onEditName;

  String get _initials {
    final name = profile.displayName.isNotEmpty
        ? profile.displayName
        : profile.email.split('@').first;
    if (name.isEmpty) return '?';
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final progression = profile.progression;
    final selectedRank = profile.rankOptions
        .where((rank) => rank.id == profile.selectedRankId && rank.unlocked)
        .firstOrNull;

    return Column(
      children: [
        // Ramka awatara w kolorze rangi (nagroda za poziom)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: progression != null
                  ? rankColor(progression.rankIndex)
                  : colorScheme.outlineVariant,
              width: 4,
            ),
          ),
          child: CircleAvatar(
            radius: 44,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              _initials,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (progression != null) ...[
          const SizedBox(height: 8),
          Text(
            '${selectedRank?.name ?? progression.rankName} · poziom ${progression.level}',
            style: TextStyle(
              color: rankColor(progression.rankIndex),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 40),
            Flexible(
              child: Text(
                profile.displayName,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Zmień nazwę gracza',
              onPressed: onEditName,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${profile.email} · dołączono ${formatDate(profile.createdAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RankSelectorCard extends StatelessWidget {
  const _RankSelectorCard({required this.profile, required this.onChanged});

  final UserProfile profile;
  final Future<void> Function() onChanged;

  Future<void> _showRanks(BuildContext context) async {
    final options = profile.rankOptions.isNotEmpty
        ? profile.rankOptions
        : fallbackRankOptions(profile.progression?.level ?? 1);
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _RankPickerSheet(
        profile: profile,
        options: options,
      ),
    );
    if (selected != null) {
      try {
        await ProfileApi.instance.selectRank(selected);
        await onChanged();
      } on ApiException catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = profile.rankOptions
        .where((rank) => rank.id == profile.selectedRankId && rank.unlocked)
        .firstOrNull;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.workspace_premium_outlined),
        title: const Text(
          'Twoja ranga',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle:
            Text(selected?.name ?? profile.progression?.rankName ?? 'Turysta'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showRanks(context),
      ),
    );
  }
}

class _RankPickerSheet extends StatelessWidget {
  const _RankPickerSheet({
    required this.profile,
    required this.options,
  });

  final UserProfile profile;
  final List<RankOption> options;

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
              'Wybierz tytuł, który pokazujesz',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Odblokowane tytuły możesz zmieniać w dowolnym momencie.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final rank = options[index];
                  final isSelected = rank.id == profile.selectedRankId;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      rank.unlocked
                          ? Icons.workspace_premium
                          : Icons.lock_outline,
                      color: rank.unlocked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            rank.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: rank.unlocked
                                  ? null
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check, color: theme.colorScheme.primary),
                      ],
                    ),
                    subtitle: Text(
                      '${rank.description} · ma ją '
                      '${_formatPercentage(rank.percentage)}% graczy',
                    ),
                    enabled: rank.unlocked,
                    onTap: rank.unlocked
                        ? () => Navigator.pop(context, rank.id)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPercentage(double percentage) =>
      percentage == percentage.roundToDouble()
          ? percentage.toStringAsFixed(0)
          : percentage.toStringAsFixed(1);
}

List<RankOption> fallbackRankOptions(int level) {
  const ranks = [
    ('level-tourist', 'Turysta', 1),
    ('level-walker', 'Spacerowicz', 3),
    ('level-explorer', 'Odkrywca', 5),
    ('level-tracker', 'Tropiciel', 8),
    ('level-guide', 'Przewodnik', 11),
    ('level-heritage', 'Strażnik Dziedzictwa', 17),
    ('level-legend', 'Legenda Wrocławia', 20),
  ];
  return [
    for (final rank in ranks)
      RankOption(
        id: rank.$1,
        name: rank.$2,
        description: 'Osiągnij poziom ${rank.$3}.',
        unlocked: level >= rank.$3,
        percentage: 0,
      ),
  ];
}

// ---------------------------------------------------------------------------
// Karta ze statystykami
// ---------------------------------------------------------------------------

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.profile, required this.colorScheme});

  final UserProfile profile;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (profile.progress * 100).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Postęp odkrywania Wrocławia',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: profile.progress,
                      minHeight: 12,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$percent%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.check_circle_outline,
                  value: '${profile.visitedCount}',
                  label: 'Odwiedzone',
                  color: Colors.green.shade600,
                ),
                _StatItem(
                  icon: Icons.location_on_outlined,
                  value: '${profile.totalMonuments}',
                  label: 'Wszystkie',
                  color: colorScheme.primary,
                ),
                _StatItem(
                  icon: Icons.explore_outlined,
                  value: '${profile.totalMonuments - profile.visitedCount}',
                  label: 'Pozostało',
                  color: Colors.orange.shade700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _CategoryProgressCard extends StatefulWidget {
  const _CategoryProgressCard({required this.profile});

  final UserProfile profile;

  @override
  State<_CategoryProgressCard> createState() => _CategoryProgressCardState();
}

class _CategoryProgressCardState extends State<_CategoryProgressCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = widget.profile.categoryProgress;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.category_outlined, color: colorScheme.primary),
            title: const Text(
              'Odkrywanie kategorii Wrocławia',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              categories.isEmpty
                  ? 'Dotknij, aby zobaczyć szczegóły'
                  : '${categories.where((item) => item.visited > 0).length} z ${categories.length} rodzajów rozpoczętych',
            ),
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onTap: categories.isEmpty
                ? null
                : () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  for (final item in categories)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _CategoryProgressRow(item: item),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryProgressRow extends StatelessWidget {
  const _CategoryProgressRow({required this.item});

  final CategoryProgress item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (item.progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(item.category.icon,
                size: 19, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.category.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${item.visited}/${item.total} ($percent%)',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: item.progress,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Kafelek ostatniej wizyty
// ---------------------------------------------------------------------------

class _RecentVisitTile extends StatelessWidget {
  const _RecentVisitTile({required this.visit});

  final RecentVisit visit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rarity = visit.rarity;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rarity.color.withAlpha(40),
          foregroundImage:
              visit.thumbUrl != null ? NetworkImage(visit.thumbUrl!) : null,
          child: Icon(visit.category.icon, color: rarity.color),
        ),
        title: Text(
          visit.monumentName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${formatDate(visit.visitedAt)} · ${rarity.label}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          '+${visit.xpEarned} XP',
          style: TextStyle(
            color: Colors.orange.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Zmiana nazwy gracza
// ---------------------------------------------------------------------------

/// Okno sam zarządza kontrolerem pola: niszczy go dopiero, gdy samo zniknie
/// (wcześniej kontroler był niszczony w trakcie animacji zamykania -> crash).
class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final _controller = TextEditingController(text: widget.initialName);
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await UsersApi.instance.updateDisplayName(_controller.text);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nazwa gracza'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 24,
        enabled: !_saving,
        onSubmitted: (_) => _saving ? null : _save(),
        decoration: InputDecoration(
          helperText: '3–24 znaki: litery, cyfry, _ . -',
          errorText: _error,
          errorMaxLines: 3,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Zapisz'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Osiągnięcia – podgląd ostatnich + przejście do pełnej listy (tor B)
// ---------------------------------------------------------------------------

class _AchievementsPreview extends StatelessWidget {
  const _AchievementsPreview({required this.profile, required this.onChanged});

  final UserProfile profile;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Osiągnięcia ${profile.achievementsUnlocked}/${profile.achievementsTotal}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (profile.recentAchievements.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Odwiedź pierwszy zabytek, aby zdobyć pierwszą odznakę.',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              for (final badge in profile.recentAchievements)
                AchievementBadgeTile(badge: badge),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.chevron_right),
                label: const Text('Zobacz wszystkie'),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AchievementsScreen()),
                  );
                  await onChanged();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Znajomi – kod gracza, liczba znajomych i oczekujące zaproszenia
// ---------------------------------------------------------------------------

class _FriendsCard extends StatelessWidget {
  const _FriendsCard({required this.profile, required this.onChanged});

  final UserProfile profile;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = profile.incomingRequests;
    final code = profile.friendCode;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Badge(
          isLabelVisible: pending > 0,
          label: Text('$pending'),
          child: Icon(Icons.group, color: theme.colorScheme.primary),
        ),
        title: Text(
          'Znajomi (${profile.friendsCount})',
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          [
            if (code != null) 'Twój kod: #$code',
            if (pending > 0) 'nowe zaproszenia: $pending',
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FriendsScreen()),
          );
          await onChanged();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tryb demo („teleport”) – do prezentacji bez chodzenia po mieście
// ---------------------------------------------------------------------------

class _DemoModeCard extends StatelessWidget {
  const _DemoModeCard();

  @override
  Widget build(BuildContext context) {
    final demo = DemoMode.instance;
    return Card(
      child: ValueListenableBuilder<bool>(
        valueListenable: demo.enabled,
        builder: (context, enabled, _) => SwitchListTile(
          secondary: const Icon(Icons.touch_app_outlined),
          title: const Text('Tryb demo (teleport)'),
          subtitle: const Text(
            'Przytrzymaj palec na mapie (na komputerze: prawy przycisk myszy), '
            'aby przenieść się w to miejsce – '
            'odkrywaj perełki i odznaczaj zabytki bez wychodzenia z domu.',
          ),
          value: enabled,
          onChanged: demo.setEnabled,
        ),
      ),
    );
  }
}
