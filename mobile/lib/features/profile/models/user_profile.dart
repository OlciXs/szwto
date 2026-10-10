import '../../../core/models/monument_category.dart';
import '../../../core/models/rarity.dart';

class UserProfile {
  final int id;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final int visitedCount;
  final int totalMonuments;
  final List<RecentVisit> recentVisits;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.visitedCount,
    required this.totalMonuments,
    required this.recentVisits,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
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
