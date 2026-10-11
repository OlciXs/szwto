import '../../../core/models/monument_category.dart';
import '../../../core/models/rarity.dart';

/// Dane karty zabytku (backend: toMonumentCard w monument.mapper.ts).
/// Używane w gablotce (tor D) i kolekcji kart (tor C).
class MonumentCardData {
  final int id;
  final String name;
  final MonumentCategory category;
  final String? rawType;
  final Rarity rarity;
  final String? builtLabel;
  final String? thumbUrl;

  MonumentCardData({
    required this.id,
    required this.name,
    required this.category,
    required this.rarity,
    this.rawType,
    this.builtLabel,
    this.thumbUrl,
  });

  factory MonumentCardData.fromJson(Map<String, dynamic> json) => MonumentCardData(
        id: json['id'] as int,
        name: json['name'] as String,
        category: MonumentCategory.fromApi(json['category'] as String?),
        rawType: json['rawType'] as String?,
        rarity: Rarity.fromApi(json['rarity'] as String?),
        builtLabel: json['builtLabel'] as String?,
        thumbUrl: json['thumbUrl'] as String?,
      );
}
