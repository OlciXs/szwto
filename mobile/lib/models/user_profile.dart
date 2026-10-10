class UserProfile {
  final int id;
  final String email;
  final DateTime createdAt;
  final int visitedCount;
  final int totalMonuments;
  final List<RecentVisit> recentVisits;

  UserProfile({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.visitedCount,
    required this.totalMonuments,
    required this.recentVisits,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
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
  final String monumentDescription;
  final double latitude;
  final double longitude;
  final DateTime visitedAt;

  RecentVisit({
    required this.monumentId,
    required this.monumentName,
    required this.monumentDescription,
    required this.latitude,
    required this.longitude,
    required this.visitedAt,
  });

  factory RecentVisit.fromJson(Map<String, dynamic> json) {
    return RecentVisit(
      monumentId: json['monumentId'] as int,
      monumentName: json['monumentName'] as String,
      monumentDescription: json['monumentDescription'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      visitedAt: DateTime.parse(json['visitedAt'] as String).toLocal(),
    );
  }
}
