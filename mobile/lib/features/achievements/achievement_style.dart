import 'package:flutter/material.dart';

import 'models/achievement.dart';

/// Nazwy ikon z backendu (definitions.ts) -> ikony Material.
const _icons = <String, IconData>{
  'footprint': Icons.directions_walk,
  'explore': Icons.explore,
  'map': Icons.map,
  'workspace_premium': Icons.workspace_premium,
  'star': Icons.star,
  'stars': Icons.stars,
  'military_tech': Icons.military_tech,
  'diamond': Icons.diamond,
  'auto_awesome': Icons.auto_awesome,
  'church': Icons.church,
  'water': Icons.water,
  'apartment': Icons.apartment,
  'castle': Icons.castle,
  'account_balance': Icons.account_balance,
  'palette': Icons.palette,
  'park': Icons.park,
  'factory': Icons.factory,
  'location_city': Icons.location_city,
  'category': Icons.category,
  'shield': Icons.shield,
  'brush': Icons.brush,
  'train': Icons.train,
  'architecture': Icons.architecture,
  'construction': Icons.construction,
  'hourglass_bottom': Icons.hourglass_bottom,
  'history': Icons.history,
  'route': Icons.route,
  'public': Icons.public,
  'menu_book': Icons.menu_book,
  'bolt': Icons.bolt,
  'nightlight': Icons.nightlight,
  'wb_twilight': Icons.wb_twilight,
  'gavel': Icons.gavel,
  'help': Icons.help_outline,
};

IconData achievementIcon(String name) => _icons[name] ?? Icons.emoji_events;

/// Kolor medalu: brąz / srebro / złoto, jednostopniowe – kolor motywu.
Color achievementColor(AchievementTier? tier, ColorScheme scheme) => switch (tier) {
      AchievementTier.bronze => const Color(0xFFB87333),
      AchievementTier.silver => const Color(0xFF8E9AA6),
      AchievementTier.gold => const Color(0xFFE0A800),
      null => scheme.primary,
    };

/// Kolory ramki awatara dla kolejnych rang (Turysta … Legenda Wrocławia).
const rankColors = <Color>[
  Color(0xFF90A4AE),
  Color(0xFF26A69A),
  Color(0xFF42A5F5),
  Color(0xFF5C6BC0),
  Color(0xFF8E24AA),
  Color(0xFFD81B60),
  Color(0xFFF4511E),
  Color(0xFFFFB300),
];

Color rankColor(int index) => rankColors[index.clamp(0, rankColors.length - 1)];
