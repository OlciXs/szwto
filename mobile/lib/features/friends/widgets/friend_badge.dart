import 'package:flutter/material.dart';

/// Zielony znaczek „ZNAJOMY” – stawiamy go po prawej od nicku znajomego.
class FriendBadge extends StatelessWidget {
  const FriendBadge({super.key, this.compact = false, this.margin = const EdgeInsets.only(left: 6)});

  final bool compact;
  final EdgeInsetsGeometry margin;

  static const color = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 7, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'ZNAJOMY',
        style: TextStyle(
          color: color,
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
