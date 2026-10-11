import '../../achievements/models/achievement.dart';
import '../../friends/models/friend.dart';
import '../../showcase/models/showcase.dart';

/// Publiczny profil gracza (GET /users/:id) – bez e-maila.
class PublicProfile {
  final int id;
  final String displayName;

  /// Publiczny tag gracza (bez #) – po nim zapraszamy do znajomych.
  final String friendCode;
  final DateTime createdAt;
  final bool isMe;

  /// Relacja oglądającego z tym graczem (znajomi / zaproszenie / brak).
  final FriendStatus friendStatus;
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
    this.friendCode = '',
    required this.createdAt,
    required this.isMe,
    this.friendStatus = FriendStatus.none,
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
      friendCode: json['friendCode'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      isMe: json['isMe'] as bool? ?? false,
      friendStatus: FriendStatus.fromApi(json['friendStatus'] as String?),
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

  bool get isFriend => friendStatus == FriendStatus.friends;

  PublicProfile copyWith({FriendStatus? friendStatus}) => PublicProfile(
        id: id,
        displayName: displayName,
        friendCode: friendCode,
        createdAt: createdAt,
        isMe: isMe,
        friendStatus: friendStatus ?? this.friendStatus,
        level: level,
        rankIndex: rankIndex,
        rankName: rankName,
        totalXp: totalXp,
        visitedCount: visitedCount,
        achievementsUnlocked: achievementsUnlocked,
        achievementsTotal: achievementsTotal,
        recentAchievements: recentAchievements,
        showcase: showcase,
      );
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
  final bool isFriend;

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
    this.isFriend = false,
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
        isFriend: json['isFriend'] as bool? ?? false,
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
