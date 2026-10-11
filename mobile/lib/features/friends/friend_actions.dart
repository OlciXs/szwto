import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../achievements/widgets/rewards_dialog.dart';
import 'friends_api.dart';
import 'models/friend.dart';

/// Wspólne akcje znajomych (ekran znajomych, profil publiczny): wywołanie API,
/// komunikat i ewentualne okno nagród. Zwraca null, gdy akcja się nie udała.
class FriendActions {
  FriendActions._();

  static Future<FriendActionResult?> addByCode(BuildContext context, String code) =>
      _run(context, () => FriendsApi.instance.addByCode(code));

  static Future<FriendActionResult?> accept(BuildContext context, int userId) =>
      _run(context, () => FriendsApi.instance.accept(userId));

  /// Usunięcie znajomego (z potwierdzeniem), odrzucenie lub anulowanie zaproszenia.
  static Future<bool> remove(
    BuildContext context,
    int userId, {
    required String successMessage,
    String? confirmName,
  }) async {
    if (confirmName != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Usunąć ze znajomych?'),
          content: Text('$confirmName zniknie z Twojej listy znajomych.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Usuń'),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return false;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FriendsApi.instance.remove(userId);
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      return true;
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return false;
    }
  }

  static Future<FriendActionResult?> _run(
    BuildContext context,
    Future<FriendActionResult> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await action();
      messenger.showSnackBar(SnackBar(content: Text(result.message)));
      final rewards = result.rewards;
      if (rewards != null && context.mounted) await showRewards(context, rewards);
      return result;
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return null;
    }
  }
}
