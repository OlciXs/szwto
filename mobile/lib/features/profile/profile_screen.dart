import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/demo_mode.dart';
import '../../core/format.dart';
import '../../core/routes.dart';
import '../../core/widgets/error_view.dart';
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
      final profile = await ProfileApi.instance.getProfile();
      if (!mounted) return;
      setState(() => _profile = profile);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
          _ProfileHeader(profile: profile, colorScheme: colorScheme),
          const SizedBox(height: 24),
          _StatsCard(profile: profile, colorScheme: colorScheme),
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
            ...profile.recentVisits.map((visit) => _RecentVisitTile(visit: visit)),
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

          // ---------- Sekcje innych torów ----------
          const SizedBox(height: 24),
          _FutureSectionCard(
            icon: Icons.workspace_premium_outlined,
            title: 'Gablotka',
            subtitle: 'Wkrótce – wystaw swoje najlepsze karty dla innych graczy.',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
          _FutureSectionCard(
            icon: Icons.emoji_events_outlined,
            title: 'Osiągnięcia',
            subtitle: 'Wkrótce – odznaki za odkrywanie kolejnych typów zabytków.',
            colorScheme: colorScheme,
          ),

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
  const _ProfileHeader({required this.profile, required this.colorScheme});

  final UserProfile profile;
  final ColorScheme colorScheme;

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

    return Column(
      children: [
        CircleAvatar(
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
        const SizedBox(height: 12),
        Text(
          profile.displayName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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

// ---------------------------------------------------------------------------
// Karta sekcji „wkrótce"
// ---------------------------------------------------------------------------

class _FutureSectionCard extends StatelessWidget {
  const _FutureSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colorScheme,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: colorScheme.surfaceContainerLow,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer.withAlpha(128),
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.lock_outline,
          color: colorScheme.onSurfaceVariant.withAlpha(128),
          size: 20,
        ),
      ),
    );
  }
}
