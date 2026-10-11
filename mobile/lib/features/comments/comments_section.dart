import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/location.dart';
import '../achievements/achievement_style.dart';
import '../achievements/widgets/rewards_dialog.dart';
import '../monuments/models/monument.dart';
import '../users/public_profile_screen.dart';
import 'comments_api.dart';
import 'models/comment.dart';

/// Mini forum przy zabytku (issue #6) – TOR D.
/// Czytać mogą wszyscy; pisać tylko gracze, którzy odwiedzili zabytek
/// ORAZ są teraz na miejscu (sprawdza serwer). Klik w autora -> jego profil.
class CommentsSection extends StatefulWidget {
  const CommentsSection({super.key, required this.monument});

  final Monument monument;

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _controller = TextEditingController();

  List<MonumentComment> _comments = [];
  int _total = 0;
  bool _visited = false;
  bool _hasMore = false;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // po odznaczeniu zabytku na tym ekranie pojawia się pole komentarza
    if (widget.monument.visited && !_visited) _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await CommentsApi.instance.getComments(
        widget.monument.id,
        before: more && _comments.isNotEmpty ? _comments.last.id : null,
      );
      if (!mounted) return;
      setState(() {
        _comments = more ? [..._comments, ...page.comments] : page.comments;
        _total = page.total;
        _visited = page.visited;
        _hasMore = page.hasMore;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final position = await LocationService.positionForVisit();
      final rewards = await CommentsApi.instance.addComment(
        widget.monument.id,
        body,
        position.latitude,
        position.longitude,
      );
      _controller.clear();
      await _load();
      if (mounted && !rewards.isEmpty) await showRewards(context, rewards);
    } on ApiException catch (e) {
      if (mounted) setState(() => _sendError = e.message);
    } on LocationException catch (e) {
      if (mounted) setState(() => _sendError = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(MonumentComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć komentarz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Usuń')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await CommentsApi.instance.deleteComment(comment.id);
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _openAuthor(CommentAuthor author) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(userId: author.id, initialName: author.displayName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Komentarze graczy${_total > 0 ? ' ($_total)' : ''}',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildComposer(theme, scheme),
        const SizedBox(height: 8),
        if (_error != null)
          ListTile(
            leading: Icon(Icons.cloud_off, color: scheme.error),
            title: Text(_error!),
            trailing: TextButton(onPressed: _load, child: const Text('Ponów')),
          )
        else if (_loading && _comments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Nikt jeszcze nie podzielił się wrażeniami z tego miejsca.',
              style: theme.textTheme.bodySmall,
            ),
          )
        else ...[
          for (final c in _comments) _CommentTile(
            comment: c,
            onAuthorTap: () => _openAuthor(c.author),
            onDelete: c.isMine ? () => _delete(c) : null,
          ),
          if (_hasMore)
            Center(
              child: TextButton(
                onPressed: _loading ? null : () => _load(more: true),
                child: const Text('Pokaż starsze'),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildComposer(ThemeData theme, ColorScheme scheme) {
    if (!_visited) {
      return Card(
        color: scheme.surfaceContainerLow,
        child: const ListTile(
          leading: Icon(Icons.forum_outlined),
          title: Text('Odwiedź ten zabytek, aby dołączyć do rozmowy'),
          subtitle: Text('Komentować można tylko na miejscu, po odznaczeniu zabytku.'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          minLines: 1,
          maxLines: 4,
          maxLength: 500,
          enabled: !_sending,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Podziel się wrażeniami z tego miejsca…',
            border: const OutlineInputBorder(),
            suffixIcon: _sending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(icon: const Icon(Icons.send), onPressed: _send),
          ),
        ),
        Text(
          'Komentarz dodasz, będąc na miejscu (do ${widget.monument.visitRadius} m od zabytku).',
          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (_sendError != null) ...[
          const SizedBox(height: 6),
          Text(
            _sendError!,
            style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.onAuthorTap, this.onDelete});

  final MonumentComment comment;
  final VoidCallback onAuthorTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = comment.author;
    final color = rankColor(author.rankIndex);
    final initials = author.displayName.isEmpty
        ? '?'
        : author.displayName.substring(0, author.displayName.length >= 2 ? 2 : 1).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onAuthorTap,
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: color,
              child: Text(
                initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    InkWell(
                      onTap: onAuthorTap,
                      child: Text(
                        author.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      'poz. ${author.level} · ${author.rankName}',
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                    Text('· ${timeAgo(comment.createdAt)}', style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Usuń komentarz',
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
