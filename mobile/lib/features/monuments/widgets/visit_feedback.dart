import 'package:flutter/material.dart';

import '../models/monument.dart';

/// Komunikat po odznaczeniu zabytku. Tor B (XP / achievementy) rozbuduje go
/// o poziom i odblokowane odznaki z `result.rewards`.
void showVisitFeedback(BuildContext context, VisitResult result) {
  final xp = result.xpEarned > 0 ? '  +${result.xpEarned} XP' : '';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${result.message}$xp'),
      backgroundColor: Colors.green.shade700,
    ),
  );
}
