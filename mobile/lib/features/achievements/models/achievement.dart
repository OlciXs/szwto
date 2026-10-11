/// Stopień osiągnięcia (null = jednostopniowe).
enum AchievementTier {
  bronze('BRONZE', 'brąz'),
  silver('SILVER', 'srebro'),
  gold('GOLD', 'złoto');

  const AchievementTier(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static AchievementTier? fromApi(Object? value) {
    for (final tier in values) {
      if (tier.apiValue == value) return tier;
    }
    return null;
  }
}

/// Osiągnięcie z postępem (GET /achievements).
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String group;
  final String groupLabel;
  final AchievementTier? tier;
  final int xp;
  final bool secret;
  final int target;
  final int progress;
  final bool unlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.group,
    required this.groupLabel,
    required this.xp,
    required this.secret,
    required this.target,
    required this.progress,
    required this.unlocked,
    this.tier,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final unlockedAt = json['unlockedAt'] as String?;
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      group: json['group'] as String? ?? '',
      groupLabel: json['groupLabel'] as String? ?? '',
      tier: AchievementTier.fromApi(json['tier']),
      xp: json['xp'] as int? ?? 0,
      secret: json['secret'] as bool? ?? false,
      target: json['target'] as int? ?? 1,
      progress: json['progress'] as int? ?? 0,
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: unlockedAt != null ? DateTime.parse(unlockedAt).toLocal() : null,
    );
  }

  double get ratio => target == 0 ? 0 : (progress / target).clamp(0, 1).toDouble();
}

/// Krótka forma – świeżo odblokowane (rewards) i ostatnie w profilu.
class AchievementBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementTier? tier;
  final int xp;

  AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.xp,
    this.tier,
  });

  factory AchievementBadge.fromJson(Map<String, dynamic> json) => AchievementBadge(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        icon: json['icon'] as String? ?? '',
        tier: AchievementTier.fromApi(json['tier']),
        xp: json['xp'] as int? ?? 0,
      );
}

/// Pole `rewards` z odpowiedzi wizyty i POST /events.
class Rewards {
  final int xpGained;
  final int level;
  final bool levelUp;
  final String? rank;
  final bool rankUp;
  final List<String> newPerks;
  final List<AchievementBadge> newAchievements;

  Rewards({
    required this.xpGained,
    required this.level,
    required this.levelUp,
    required this.rankUp,
    required this.newPerks,
    required this.newAchievements,
    this.rank,
  });

  factory Rewards.fromJson(Map<String, dynamic> json) {
    final progression = json['progression'] as Map<String, dynamic>? ?? const {};
    return Rewards(
      xpGained: progression['xpGained'] as int? ?? 0,
      level: progression['level'] as int? ?? 1,
      levelUp: progression['levelUp'] as bool? ?? false,
      rank: progression['rank'] as String?,
      rankUp: progression['rankUp'] as bool? ?? false,
      newPerks: (progression['newPerks'] as List<dynamic>? ?? const [])
          .cast<String>(),
      newAchievements: (json['newAchievements'] as List<dynamic>? ?? const [])
          .map((a) => AchievementBadge.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isEmpty => !levelUp && newAchievements.isEmpty;
}
