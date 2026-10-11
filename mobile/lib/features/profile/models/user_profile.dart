import '../../../core/models/monument_category.dart';
import '../../../core/models/rarity.dart';
import '../../achievements/models/achievement.dart';
import '../../achievements/models/progression.dart';
import '../../showcase/models/showcase.dart';

class UserProfile {
  final int id;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final int visitedCount;
  final int totalMonuments;
  final List<CategoryProgress> categoryProgress;
  final String? selectedRankId;
  final List<RankOption> rankOptions;
  final List<RecentVisit> recentVisits;

  /// Tor B – poziom i osiągnięcia (null przy starszym backendzie).
  final Progression? progression;
  final int achievementsUnlocked;
  final int achievementsTotal;
  final List<AchievementBadge> recentAchievements;

  /// Tor D – gablotka (null przy starszym backendzie).
  final Showcase? showcase;

  /// Znajomi – mój kod (np. K7Q2MX), liczba znajomych i oczekujących zaproszeń.
  final String? friendCode;
  final int friendsCount;
  final int incomingRequests;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.visitedCount,
    required this.totalMonuments,
    this.categoryProgress = const [],
    this.selectedRankId,
    this.rankOptions = const [],
    required this.recentVisits,
    this.progression,
    this.achievementsUnlocked = 0,
    this.achievementsTotal = 0,
    this.recentAchievements = const [],
    this.showcase,
    this.friendCode,
    this.friendsCount = 0,
    this.incomingRequests = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final progression = json['progression'] as Map<String, dynamic>?;
    final achievements =
        json['achievements'] as Map<String, dynamic>? ?? const {};
    final showcase = json['showcase'] as Map<String, dynamic>?;
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      visitedCount: json['visitedCount'] as int,
      totalMonuments: json['totalMonuments'] as int,
      categoryProgress: (json['categoryProgress'] as List<dynamic>? ?? const [])
          .map(
              (item) => CategoryProgress.fromJson(item as Map<String, dynamic>))
          .toList(),
      selectedRankId: json['selectedRankId'] as String?,
      rankOptions: (json['rankOptions'] as List<dynamic>? ?? const [])
          .map((item) => RankOption.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentVisits: (json['recentVisits'] as List<dynamic>)
          .map((item) => RecentVisit.fromJson(item as Map<String, dynamic>))
          .toList(),
      progression:
          progression != null ? Progression.fromJson(progression) : null,
      achievementsUnlocked: achievements['unlockedCount'] as int? ?? 0,
      achievementsTotal: achievements['total'] as int? ?? 0,
      recentAchievements: (achievements['recent'] as List<dynamic>? ?? const [])
          .map((a) => AchievementBadge.fromJson(a as Map<String, dynamic>))
          .toList(),
      showcase: showcase != null ? Showcase.fromJson(showcase) : null,
      friendCode: json['friendCode'] as String?,
      friendsCount: json['friendsCount'] as int? ?? 0,
      incomingRequests: json['incomingRequests'] as int? ?? 0,
    );
  }

  double get progress => totalMonuments > 0 ? visitedCount / totalMonuments : 0;

  UserProfile copyWithCategoryProgress(List<CategoryProgress> progress) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      createdAt: createdAt,
      visitedCount: visitedCount,
      totalMonuments: totalMonuments,
      categoryProgress: progress,
      selectedRankId: selectedRankId,
      rankOptions: rankOptions,
      recentVisits: recentVisits,
      progression: progression,
      achievementsUnlocked: achievementsUnlocked,
      achievementsTotal: achievementsTotal,
      recentAchievements: recentAchievements,
      showcase: showcase,
      friendCode: friendCode,
      friendsCount: friendsCount,
      incomingRequests: incomingRequests,
    );
  }
}

class RankOption {
  final String id;
  final String name;
  final String description;
  final bool unlocked;
  final double percentage;

  const RankOption({
    required this.id,
    required this.name,
    required this.description,
    required this.unlocked,
    required this.percentage,
  });

  factory RankOption.fromJson(Map<String, dynamic> json) => RankOption(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        unlocked: json['unlocked'] as bool? ?? false,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      );
}

class CategoryProgress {
  final MonumentCategory category;
  final int visited;
  final int total;

  const CategoryProgress({
    required this.category,
    required this.visited,
    required this.total,
  });

  factory CategoryProgress.fromJson(Map<String, dynamic> json) {
    return CategoryProgress(
      category: MonumentCategory.fromApi(json['category'] as String?),
      visited: json['visited'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }

  double get progress => total > 0 ? (visited / total).clamp(0.0, 1.0) : 0;
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
