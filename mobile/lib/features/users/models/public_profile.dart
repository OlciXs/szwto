import '../../achievements/models/achievement.dart';
import '../../showcase/models/showcase.dart';

/// Publiczny profil gracza (GET /users/:id) – bez e-maila.
class PublicProfile {
  final int id;
  final String displayName;
  final DateTime createdAt;
  final bool isMe;
  final int level;
  final int rankIndex;
  final String rankName;
  final int totalXp;
  final int visitedCount;
  final int achievementsUnlocked;
  final int achievementsTotal;
  final List<AchievementBadge> recentAchievements;
  final Showcase showcase;

  PublicProfile({
    required this.id,
    required this.displayName,
    required this.createdAt,
    required this.isMe,
    required this.level,
    required this.rankIndex,
    required this.rankName,
    required this.totalXp,
    required this.visitedCount,
    required this.achievementsUnlocked,
    required this.achievementsTotal,
    required this.recentAchievements,
    required this.showcase,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    final rank = json['rank'] as Map<String, dynamic>? ?? const {};
    final achievements = json['achievements'] as Map<String, dynamic>? ?? const {};
    return PublicProfile(
      id: json['id'] as int,
      displayName: json['displayName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      isMe: json['isMe'] as bool? ?? false,
      level: json['level'] as int? ?? 1,
      rankIndex: rank['index'] as int? ?? 0,
      rankName: rank['name'] as String? ?? 'Turysta',
      totalXp: json['totalXp'] as int? ?? 0,
      visitedCount: json['visitedCount'] as int? ?? 0,
      achievementsUnlocked: achievements['unlockedCount'] as int? ?? 0,
      achievementsTotal: achievements['total'] as int? ?? 0,
      recentAchievements: (achievements['recent'] as List<dynamic>? ?? const [])
          .map((a) => AchievementBadge.fromJson(a as Map<String, dynamic>))
          .toList(),
      showcase: Showcase.fromJson(json['showcase'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

/// Wiersz rankingu (GET /users/leaderboard).
class LeaderboardEntry {
  final int position;
  final int id;
  final String displayName;
  final int totalXp;
  final int visitedCount;
  final int level;
  final int rankIndex;
  final String rankName;
  final bool isMe;

  LeaderboardEntry({
    required this.position,
    required this.id,
    required this.displayName,
    required this.totalXp,
    required this.visitedCount,
    required this.level,
    required this.rankIndex,
    required this.rankName,
    required this.isMe,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        position: json['position'] as int,
        id: json['id'] as int,
        displayName: json['displayName'] as String,
        totalXp: json['totalXp'] as int? ?? 0,
        visitedCount: json['visitedCount'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        rankIndex: json['rankIndex'] as int? ?? 0,
        rankName: json['rankName'] as String? ?? 'Turysta',
        isMe: json['isMe'] as bool? ?? false,
      );
}

class Leaderboard {
  final int totalPlayers;
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? me;

  Leaderboard({required this.totalPlayers, required this.entries, this.me});

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    final me = json['me'] as Map<String, dynamic>?;
    return Leaderboard(
      totalPlayers: json['totalPlayers'] as int? ?? 0,
      entries: (json['entries'] as List<dynamic>? ?? const [])
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      me: me != null ? LeaderboardEntry.fromJson(me) : null,
    );
  }
}
