import '../../achievements/models/achievement.dart';

/// Relacja z innym graczem z punktu widzenia oglądającego.
enum FriendStatus {
  none,

  /// Wysłałem zaproszenie – czeka na akceptację.
  outgoing,

  /// Ta osoba zaprosiła mnie.
  incoming,
  friends;

  static FriendStatus fromApi(String? value) => switch (value) {
        'OUTGOING' || 'PENDING' => FriendStatus.outgoing,
        'INCOMING' => FriendStatus.incoming,
        'FRIENDS' || 'ACCEPTED' => FriendStatus.friends,
        _ => FriendStatus.none,
      };
}

/// Gracz na liście znajomych / zaproszeń (GET /friends).
class FriendUser {
  final int id;
  final String displayName;
  final String friendCode;
  final int level;
  final int rankIndex;
  final String rankName;
  final int totalXp;
  final int visitedCount;

  FriendUser({
    required this.id,
    required this.displayName,
    required this.friendCode,
    required this.level,
    required this.rankIndex,
    required this.rankName,
    required this.totalXp,
    required this.visitedCount,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) => FriendUser(
        id: json['id'] as int,
        displayName: json['displayName'] as String,
        friendCode: json['friendCode'] as String? ?? '',
        level: json['level'] as int? ?? 1,
        rankIndex: json['rankIndex'] as int? ?? 0,
        rankName: json['rankName'] as String? ?? 'Turysta',
        totalXp: json['totalXp'] as int? ?? 0,
        visitedCount: json['visitedCount'] as int? ?? 0,
      );
}

class FriendsOverview {
  /// Mój kod do udostępnienia, np. K7Q2MX (wyświetlany jako #K7Q2MX).
  final String myCode;
  final List<FriendUser> friends;
  final List<FriendUser> incoming;
  final List<FriendUser> outgoing;

  FriendsOverview({
    required this.myCode,
    required this.friends,
    required this.incoming,
    required this.outgoing,
  });

  factory FriendsOverview.fromJson(Map<String, dynamic> json) {
    List<FriendUser> list(String key) => (json[key] as List<dynamic>? ?? const [])
        .map((u) => FriendUser.fromJson(u as Map<String, dynamic>))
        .toList();
    return FriendsOverview(
      myCode: json['myCode'] as String? ?? '',
      friends: list('friends'),
      incoming: list('incoming'),
      outgoing: list('outgoing'),
    );
  }
}

/// Wynik zaproszenia / akceptacji (POST /friends, POST /friends/:id/accept).
class FriendActionResult {
  final FriendStatus status;
  final String message;
  final Rewards? rewards;

  FriendActionResult({required this.status, required this.message, this.rewards});

  factory FriendActionResult.fromJson(Map<String, dynamic> json) {
    final rewards = json['rewards'] as Map<String, dynamic>?;
    return FriendActionResult(
      status: FriendStatus.fromApi(json['status'] as String?),
      message: json['message'] as String? ?? '',
      rewards: rewards != null ? Rewards.fromJson(rewards) : null,
    );
  }
}
