import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

String _formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}';
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService.instance;

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
      final profile = await _api.getProfile();
      if (!mounted) return;
      setState(() => _profile = profile);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _logout();
        return;
      }
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mój profil'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(theme)
              : _profile != null
                  ? _buildProfileContent(theme, colorScheme, _profile!)
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
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
          // ---------- Awatar i e-mail ----------
          _ProfileHeader(profile: profile, colorScheme: colorScheme),
          const SizedBox(height: 24),

          // ---------- Statystyki ----------
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
            ...profile.recentVisits.map(
              (visit) => _RecentVisitTile(visit: visit, colorScheme: colorScheme),
            ),
          ],

          if (profile.recentVisits.isEmpty && profile.visitedCount == 0) ...[
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

          // ---------- Sekcje placeholder na przyszłość ----------
          const SizedBox(height: 24),
          _FutureSectionCard(
            icon: Icons.collections_bookmark_outlined,
            title: 'Kolekcja zabytków',
            subtitle: 'Wkrótce – tutaj pojawią się Twoje zebrane karty zabytków.',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
          _FutureSectionCard(
            icon: Icons.military_tech_outlined,
            title: 'Tytuły i odznaczenia',
            subtitle: 'Wkrótce – zdobywaj tytuły za odkrywanie nowych miejsc.',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
          _FutureSectionCard(
            icon: Icons.emoji_events_outlined,
            title: 'Osiągnięcia',
            subtitle: 'Wkrótce – odblokowuj osiągnięcia i dziel się postępami.',
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 32),

          // ---------- Wyloguj ----------
          OutlinedButton.icon(
            onPressed: _logout,
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
// Nagłówek profilu (awatar + e-mail + data rejestracji)
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.colorScheme});

  final UserProfile profile;
  final ColorScheme colorScheme;

  String _initials(String email) {
    final local = email.split('@').first;
    if (local.isEmpty) return '?';
    return local.substring(0, local.length >= 2 ? 2 : 1).toUpperCase();
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
            _initials(profile.email),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          profile.email,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Dołączono: ${_formatDate(profile.createdAt)}',
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
    final percent = (profile.progress * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Postęp odkrywania',
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
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Kafelek ostatniej wizyty
// ---------------------------------------------------------------------------

class _RecentVisitTile extends StatelessWidget {
  const _RecentVisitTile({required this.visit, required this.colorScheme});

  final RecentVisit visit;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: Icon(Icons.location_on, color: Colors.green.shade600),
        ),
        title: Text(
          visit.monumentName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _formatDate(visit.visitedAt),
          style: theme.textTheme.bodySmall,
        ),
        trailing: Icon(
          Icons.check_circle,
          color: Colors.green.shade600,
          size: 20,
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
