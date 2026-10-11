import '../../../core/models/monument_category.dart';
import '../../../core/models/rarity.dart';

DateTime? _parseDate(Object? raw) =>
    raw is String ? DateTime.parse(raw).toLocal() : null;

/// Zabytek w wersji „lekkiej” (lista na mapie: GET /monuments).
/// Używany też przez kolekcję, gablotkę i grę.
class Monument {
  final int id;
  final String name;
  final MonumentCategory category;
  final String? rawType;
  final Rarity rarity;

  /// Zabytek główny – zawsze widoczny na mapie. Pozostałe to ukryte perełki,
  /// które pojawiają się dopiero w zasięgu gracza (features/map/discovery_service.dart).
  final bool isMajor;
  final double latitude;
  final double longitude;
  final String? thumbUrl;
  final int? builtYear;
  final String? builtLabel;
  final String? era;
  final int xp;
  final int visitRadius;
  bool visited;
  DateTime? visitedAt;

  Monument({
    required this.id,
    required this.name,
    required this.category,
    required this.rarity,
    required this.latitude,
    required this.longitude,
    required this.xp,
    required this.visitRadius,
    this.isMajor = false,
    this.rawType,
    this.thumbUrl,
    this.builtYear,
    this.builtLabel,
    this.era,
    this.visited = false,
    this.visitedAt,
  });

  factory Monument.fromJson(Map<String, dynamic> json) {
    return Monument(
      id: json['id'] as int,
      name: json['name'] as String,
      category: MonumentCategory.fromApi(json['category'] as String?),
      rawType: json['rawType'] as String?,
      rarity: Rarity.fromApi(json['rarity'] as String?),
      // Starszy backend nie zna podziału – wtedy pokazujemy wszystko jako główne,
      // zamiast chować całą mapę.
      isMajor: json['isMajor'] as bool? ?? true,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      thumbUrl: json['thumbUrl'] as String?,
      builtYear: json['builtYear'] as int?,
      builtLabel: json['builtLabel'] as String?,
      era: json['era'] as String?,
      xp: json['xp'] as int? ?? 0,
      visitRadius: json['visitRadius'] as int? ?? 40,
      visited: json['visited'] as bool? ?? false,
      visitedAt: _parseDate(json['visitedAt']),
    );
  }

  /// Np. „Kamienica · XVIII wiek”.
  String get subtitle {
    final type = rawType == null || rawType!.isEmpty
        ? category.label
        : rawType![0].toUpperCase() + rawType!.substring(1);
    return builtLabel == null ? type : '$type · $builtLabel';
  }
}

class MonumentImage {
  final String thumbUrl;
  final String fullUrl;

  /// Strona pliku na Wikimedia Commons (autor i licencja).
  final String pageUrl;

  MonumentImage({
    required this.thumbUrl,
    required this.fullUrl,
    required this.pageUrl,
  });

  factory MonumentImage.fromJson(Map<String, dynamic> json) => MonumentImage(
        thumbUrl: json['thumbUrl'] as String,
        fullUrl: json['fullUrl'] as String,
        pageUrl: json['pageUrl'] as String,
      );
}

/// Pełne dane zabytku (GET /monuments/:id).
class MonumentDetails {
  final Monument monument;

  /// Typ i data, np. „Ratusz · XIII wiek”.
  final String teaser;

  /// Zajawka (1–2 zdania) – widoczna zawsze.
  final String? summary;

  /// Długi opis historyczny (akapity oddzielone pustą linią) – null przed wizytą.
  final String? description;

  /// Ciekawostka – null przed wizytą (albo gdy jej brak).
  final String? funFact;
  final bool descriptionLocked;

  /// "wikipedia" | "generated"
  final String? descriptionSource;
  final String? address;
  final MonumentImage? image;
  final String heritageLevel;
  final String? registerNumber;
  final String? wikipediaUrl;
  final int visitorsCount;

  MonumentDetails({
    required this.monument,
    required this.teaser,
    required this.descriptionLocked,
    required this.heritageLevel,
    required this.visitorsCount,
    this.summary,
    this.description,
    this.funFact,
    this.descriptionSource,
    this.address,
    this.image,
    this.registerNumber,
    this.wikipediaUrl,
  });

  factory MonumentDetails.fromJson(Map<String, dynamic> json) {
    final image = json['image'];
    return MonumentDetails(
      monument: Monument.fromJson(json),
      teaser: json['teaser'] as String? ?? '',
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      funFact: json['funFact'] as String?,
      descriptionLocked: json['descriptionLocked'] as bool? ?? true,
      descriptionSource: json['descriptionSource'] as String?,
      address: json['address'] as String?,
      image: image is Map<String, dynamic> ? MonumentImage.fromJson(image) : null,
      heritageLevel: json['heritageLevel'] as String? ?? 'BRAK',
      registerNumber: json['registerNumber'] as String?,
      wikipediaUrl: json['wikipediaUrl'] as String?,
      visitorsCount: json['visitorsCount'] as int? ?? 0,
    );
  }

  /// Akapity długiego opisu.
  List<String> get paragraphs => (description ?? '')
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
}

class VisitResult {
  final String message;
  final double distanceMeters;
  final DateTime? visitedAt;
  final bool alreadyVisited;
  final int xpEarned;

  /// Nagrody z modułów (XP/poziom – tor B, achievementy – tor B).
  /// Kształt: backend/src/events/monument-visited.event.ts (VisitRewards).
  final Map<String, dynamic> rewards;

  VisitResult({
    required this.message,
    required this.distanceMeters,
    required this.alreadyVisited,
    required this.xpEarned,
    required this.rewards,
    this.visitedAt,
  });

  factory VisitResult.fromJson(Map<String, dynamic> json) {
    return VisitResult(
      message: json['message'] as String? ?? 'Zabytek odznaczony!',
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      visitedAt: _parseDate(json['visitedAt']),
      alreadyVisited: json['alreadyVisited'] as bool? ?? false,
      xpEarned: json['xpEarned'] as int? ?? 0,
      rewards: (json['rewards'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
