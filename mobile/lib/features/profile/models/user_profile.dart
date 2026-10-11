import '../../../core/models/monument_category.dart';
import '../../../core/models/rarity.dart';
import '../../achievements/models/achievement.dart';
import '../../achievements/models/progression.dart';

class UserProfile {
  final int id;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final int visitedCount;
  final int totalMonuments;
  final List<RecentVisit> recentVisits;

  /// Tor B – poziom i osiągnięcia (null przy starszym backendzie).
  final Progression? progression;
  final int achievementsUnlocked;
  final int achievementsTotal;
  final List<AchievementBadge> recentAchievements;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.visitedCount,
    required this.totalMonuments,
    required this.recentVisits,
    this.progression,
    this.achievementsUnlocked = 0,
    this.achievementsTotal = 0,
    this.recentAchievements = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final progression = json['progression'] as Map<String, dynamic>?;
    final achievements = json['achievements'] as Map<String, dynamic>? ?? const {};
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      visitedCount: json['visitedCount'] as int,
      totalMonuments: json['totalMonuments'] as int,
      recentVisits: (json['recentVisits'] as List<dynamic>)
          .map((item) => RecentVisit.fromJson(item as Map<String, dynamic>))
          .toList(),
      progression: progression != null ? Progression.fromJson(progression) : null,
      achievementsUnlocked: achievements['unlockedCount'] as int? ?? 0,
      achievementsTotal: achievements['total'] as int? ?? 0,
      recentAchievements: (achievements['recent'] as List<dynamic>? ?? const [])
          .map((a) => AchievementBadge.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  double get progress =>
      totalMonuments > 0 ? visitedCount / totalMonuments : 0;
}

class RecentVisit {
  final int monumentId;
  final String monumentName;
  final MonumentCategory category;
  final Rarity rarity;
  final String? thumbUrl;
  final int xpEarned;
  final DateTime visitedAt;

  RecentVisit({
    required this.monumentId,
    required this.monumentName,
    required this.category,
    required this.rarity,
    required this.xpEarned,
    required this.visitedAt,
    this.thumbUrl,
  });

  factory RecentVisit.fromJson(Map<String, dynamic> json) {
    return RecentVisit(
      monumentId: json['monumentId'] as int,
      monumentName: json['monumentName'] as String,
      category: MonumentCategory.fromApi(json['category'] as String?),
      rarity: Rarity.fromApi(json['rarity'] as String?),
      thumbUrl: json['thumbUrl'] as String?,
      xpEarned: json['xpEarned'] as int? ?? 0,
      visitedAt: DateTime.parse(json['visitedAt'] as String).toLocal(),
    );
  }
}
