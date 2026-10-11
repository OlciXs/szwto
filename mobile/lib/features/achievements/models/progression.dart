/// Poziom gracza (GET /progression, także w GET /profile).
/// Zasady liczy backend: backend/src/progression/levels.ts.
class Progression {
  final int totalXp;
  final int level;
  final String rankName;

  /// 0..7 – kolor ramki awatara.
  final int rankIndex;
  final int levelStartXp;
  final int nextLevelXp;

  /// 0..1 – postęp do następnego poziomu.
  final double progress;
  final Perks perks;
  final String? nextUnlockLabel;
  final int? nextUnlockLevel;

  Progression({
    required this.totalXp,
    required this.level,
    required this.rankName,
    required this.rankIndex,
    required this.levelStartXp,
    required this.nextLevelXp,
    required this.progress,
    required this.perks,
    this.nextUnlockLabel,
    this.nextUnlockLevel,
  });

  factory Progression.fromJson(Map<String, dynamic> json) {
    final rank = json['rank'] as Map<String, dynamic>? ?? const {};
    final next = json['nextUnlock'] as Map<String, dynamic>?;
    return Progression(
      totalXp: json['totalXp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      rankName: rank['name'] as String? ?? 'Turysta',
      rankIndex: rank['index'] as int? ?? 0,
      levelStartXp: json['levelStartXp'] as int? ?? 0,
      nextLevelXp: json['nextLevelXp'] as int? ?? 50,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      perks: Perks.fromJson(json['perks'] as Map<String, dynamic>? ?? const {}),
      nextUnlockLabel: next?['label'] as String?,
      nextUnlockLevel: next?['level'] as int?,
    );
  }

  int get xpIntoLevel => totalXp - levelStartXp;
  int get xpForLevel => nextLevelXp - levelStartXp;
}

/// Nagrody za poziom.
class Perks {
  final double discoveryRadius;
  final int showcaseSlots;
  final bool radar;

  const Perks({
    required this.discoveryRadius,
    required this.showcaseSlots,
    required this.radar,
  });

  factory Perks.fromJson(Map<String, dynamic> json) => Perks(
        discoveryRadius: (json['discoveryRadius'] as num?)?.toDouble() ?? 250,
        showcaseSlots: json['showcaseSlots'] as int? ?? 1,
        radar: json['radar'] as bool? ?? false,
      );
}
