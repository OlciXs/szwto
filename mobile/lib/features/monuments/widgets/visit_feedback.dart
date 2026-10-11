import 'package:flutter/material.dart';

import '../../achievements/models/achievement.dart';
import '../../achievements/widgets/rewards_dialog.dart';
import '../models/monument.dart';

/// Po odznaczeniu zabytku: komunikat z XP (z premiami za osiągnięcia),
/// potem okna „Nowy poziom!” i „Nowe osiągnięcie!” (tor B).
Future<void> showVisitFeedback(BuildContext context, VisitResult result) async {
  final rewards = Rewards.fromJson(result.rewards);
  final xp = rewards.xpGained > 0 ? rewards.xpGained : result.xpEarned;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${result.message}${xp > 0 ? '  +$xp XP' : ''}'),
      backgroundColor: Colors.green.shade700,
    ),
  );
  if (!rewards.isEmpty) await showRewards(context, rewards);
}
