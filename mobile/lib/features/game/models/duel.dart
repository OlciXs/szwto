import '../../../core/models/monument_category.dart';
import '../../../core/models/rarity.dart';

class EligibleFriend {
  final int id;
  final String displayName;
  final String friendCode;
  final int level;
  final int rankIndex;
  final String rankName;
  final int totalXp;
  final int visitedCount;
  final bool isEligible;

  EligibleFriend({
    required this.id,
    required this.displayName,
    required this.friendCode,
    required this.level,
    required this.rankIndex,
    required this.rankName,
    required this.totalXp,
    required this.visitedCount,
    required this.isEligible,
  });

  factory EligibleFriend.fromJson(Map<String, dynamic> json) => EligibleFriend(
        id: json['id'] as int,
        displayName: json['displayName'] as String,
        friendCode: json['friendCode'] as String? ?? '',
        level: json['level'] as int? ?? 1,
        rankIndex: json['rankIndex'] as int? ?? 0,
        rankName: json['rankName'] as String? ?? 'Turysta',
        totalXp: json['totalXp'] as int? ?? 0,
        visitedCount: json['visitedCount'] as int? ?? 0,
        isEligible: json['isEligible'] as bool? ?? false,
      );
}

class DuelEligibility {
  final int myVisitedCount;
  final bool isEligible;
  final int minCardsRequired;
  final List<EligibleFriend> friends;

  DuelEligibility({
    required this.myVisitedCount,
    required this.isEligible,
    required this.minCardsRequired,
    required this.friends,
  });

  factory DuelEligibility.fromJson(Map<String, dynamic> json) {
    final rawFriends = json['friends'] as List<dynamic>? ?? const [];
    return DuelEligibility(
      myVisitedCount: json['myVisitedCount'] as int? ?? 0,
      isEligible: json['isEligible'] as bool? ?? false,
      minCardsRequired: json['minCardsRequired'] as int? ?? 10,
      friends: rawFriends
          .map((f) => EligibleFriend.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DuelSummary {
  final int id;
  final String code;
  final int rounds;
  final DateTime createdAt;
  final DateTime? finishedAt;
  final bool isCreator;
  final String creatorName;
  final String opponentName;
  final bool isBot;
  final int? myScore;
  final int? opponentScore;
  final bool hasPlayed;
  final bool opponentHasPlayed;
  final bool isFinished;
  final String status;

  DuelSummary({
    required this.id,
    required this.code,
    required this.rounds,
    required this.createdAt,
    this.finishedAt,
    required this.isCreator,
    required this.creatorName,
    required this.opponentName,
    required this.isBot,
    this.myScore,
    this.opponentScore,
    required this.hasPlayed,
    required this.opponentHasPlayed,
    required this.isFinished,
    required this.status,
  });

  factory DuelSummary.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>? ?? {};
    final opponent = json['opponent'] as Map<String, dynamic>? ?? {};
    return DuelSummary(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      rounds: json['rounds'] as int? ?? 3,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      finishedAt: json['finishedAt'] != null
          ? DateTime.tryParse(json['finishedAt'] as String)
          : null,
      isCreator: json['isCreator'] as bool? ?? true,
      creatorName: creator['displayName'] as String? ?? 'Gracz',
      opponentName: opponent['displayName'] as String? ?? 'Przeciwnik',
      isBot: json['isBot'] as bool? ?? false,
      myScore: json['myScore'] as int?,
      opponentScore: json['opponentScore'] as int?,
      hasPlayed: json['hasPlayed'] as bool? ?? false,
      opponentHasPlayed: json['opponentHasPlayed'] as bool? ?? false,
      isFinished: json['isFinished'] as bool? ?? false,
      status: json['status'] as String? ?? 'YOUR_TURN',
    );
  }
}

class DuelCardItem {
  final int id;
  final String name;
  final MonumentCategory category;
  final String? rawType;
  final Rarity rarity;
  final String? builtLabel;
  final String? thumbUrl;
  final double latitude;
  final double longitude;

  DuelCardItem({
    required this.id,
    required this.name,
    required this.category,
    this.rawType,
    required this.rarity,
    this.builtLabel,
    this.thumbUrl,
    required this.latitude,
    required this.longitude,
  });

  factory DuelCardItem.fromJson(Map<String, dynamic> json) => DuelCardItem(
        id: json['id'] as int,
        name: json['name'] as String,
        category: MonumentCategory.fromApi(json['category'] as String?),
        rawType: json['rawType'] as String?,
        rarity: Rarity.fromApi(json['rarity'] as String?),
        builtLabel: json['builtLabel'] as String?,
        thumbUrl: json['thumbUrl'] as String?,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
}

class DuelRoundData {
  final int roundNumber;
  final DuelCardItem centerMonument;
  final DuelCardItem creatorMonument;
  final DuelCardItem opponentMonument;
  final int creatorDistanceMeters;
  final int opponentDistanceMeters;
  final String closer; // 'CREATOR' | 'OPPONENT'

  DuelRoundData({
    required this.roundNumber,
    required this.centerMonument,
    required this.creatorMonument,
    required this.opponentMonument,
    required this.creatorDistanceMeters,
    required this.opponentDistanceMeters,
    required this.closer,
  });

  factory DuelRoundData.fromJson(Map<String, dynamic> json) => DuelRoundData(
        roundNumber: json['roundNumber'] as int,
        centerMonument: DuelCardItem.fromJson(json['centerMonument'] as Map<String, dynamic>),
        creatorMonument: DuelCardItem.fromJson(json['creatorMonument'] as Map<String, dynamic>),
        opponentMonument: DuelCardItem.fromJson(json['opponentMonument'] as Map<String, dynamic>),
        creatorDistanceMeters: json['creatorDistanceMeters'] as int,
        opponentDistanceMeters: json['opponentDistanceMeters'] as int,
        closer: json['closer'] as String,
      );
}

class DuelDetail {
  final int id;
  final String code;
  final int roundsCount;
  final bool isCreator;
  final String creatorName;
  final String opponentName;
  final bool isBot;
  final int? myScore;
  final int? opponentScore;
  final bool hasPlayed;
  final bool isFinished;
  final List<DuelRoundData> rounds;

  DuelDetail({
    required this.id,
    required this.code,
    required this.roundsCount,
    required this.isCreator,
    required this.creatorName,
    required this.opponentName,
    required this.isBot,
    this.myScore,
    this.opponentScore,
    required this.hasPlayed,
    required this.isFinished,
    required this.rounds,
  });

  factory DuelDetail.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>? ?? {};
    final opponent = json['opponent'] as Map<String, dynamic>? ?? {};
    final rawRounds = json['rounds'] as List<dynamic>? ?? const [];
    return DuelDetail(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      roundsCount: json['roundsCount'] as int? ?? 3,
      isCreator: json['isCreator'] as bool? ?? true,
      creatorName: creator['displayName'] as String? ?? 'Gracz',
      opponentName: opponent['displayName'] as String? ?? 'Przeciwnik',
      isBot: json['isBot'] as bool? ?? false,
      myScore: json['myScore'] as int?,
      opponentScore: json['opponentScore'] as int?,
      hasPlayed: json['hasPlayed'] as bool? ?? false,
      isFinished: json['isFinished'] as bool? ?? false,
      rounds: rawRounds
          .map((r) => DuelRoundData.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RoundResultData {
  final int roundNumber;
  final String yourChoice;
  final String closer;
  final bool isCorrect;
  final DuelCardItem centerMonument;
  final DuelCardItem creatorMonument;
  final DuelCardItem opponentMonument;
  final int creatorDistanceMeters;
  final int opponentDistanceMeters;

  RoundResultData({
    required this.roundNumber,
    required this.yourChoice,
    required this.closer,
    required this.isCorrect,
    required this.centerMonument,
    required this.creatorMonument,
    required this.opponentMonument,
    required this.creatorDistanceMeters,
    required this.opponentDistanceMeters,
  });

  factory RoundResultData.fromJson(Map<String, dynamic> json) => RoundResultData(
        roundNumber: json['roundNumber'] as int,
        yourChoice: json['yourChoice'] as String,
        closer: json['closer'] as String,
        isCorrect: json['isCorrect'] as bool,
        centerMonument: DuelCardItem.fromJson(json['centerMonument'] as Map<String, dynamic>),
        creatorMonument: DuelCardItem.fromJson(json['creatorMonument'] as Map<String, dynamic>),
        opponentMonument: DuelCardItem.fromJson(json['opponentMonument'] as Map<String, dynamic>),
        creatorDistanceMeters: json['creatorDistanceMeters'] as int,
        opponentDistanceMeters: json['opponentDistanceMeters'] as int,
      );
}

class DuelAnswersResult {
  final int score;
  final int totalRounds;
  final bool isFinished;
  final int myScore;
  final int? opponentScore;
  final String? winner; // 'YOU' | 'OPPONENT' | 'DRAW' | null
  final List<RoundResultData> roundResults;

  DuelAnswersResult({
    required this.score,
    required this.totalRounds,
    required this.isFinished,
    required this.myScore,
    this.opponentScore,
    this.winner,
    required this.roundResults,
  });

  factory DuelAnswersResult.fromJson(Map<String, dynamic> json) {
    final list = json['roundResults'] as List<dynamic>? ?? const [];
    return DuelAnswersResult(
      score: json['score'] as int,
      totalRounds: json['totalRounds'] as int,
      isFinished: json['isFinished'] as bool? ?? false,
      myScore: json['myScore'] as int,
      opponentScore: json['opponentScore'] as int?,
      winner: json['winner'] as String?,
      roundResults: list
          .map((r) => RoundResultData.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
