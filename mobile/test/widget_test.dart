import 'package:flutter_test/flutter_test.dart';
import 'package:zabytki_app/core/models/monument_category.dart';
import 'package:zabytki_app/core/models/rarity.dart';
import 'package:zabytki_app/features/monuments/models/monument.dart';

void main() {
  test('Monument.fromJson parsuje odpowiedź GET /monuments', () {
    final monument = Monument.fromJson({
      'id': 7,
      'name': 'Ratusz we Wrocławiu',
      'category': 'PUBLICZNY',
      'rawType': 'ratusz',
      'rarity': 'LEGENDARY',
      'latitude': 51.1096,
      'longitude': 17.0318,
      'thumbUrl': 'https://upload.wikimedia.org/x.jpg',
      'builtYear': 1250,
      'builtLabel': 'XIII wiek',
      'era': 'SREDNIOWIECZE',
      'xp': 150,
      'visitRadius': 75,
      'visited': true,
      'visitedAt': '2026-10-10T12:00:00.000Z',
    });

    expect(monument.id, 7);
    expect(monument.isMajor, isTrue); // brak pola (stary backend) -> widoczny
    expect(monument.category, MonumentCategory.publiczny);
    expect(monument.rarity, Rarity.legendary);
    expect(monument.visited, isTrue);
    expect(monument.visitedAt, isNotNull);
    expect(monument.subtitle, 'Ratusz · XIII wiek');
  });

  test('Monument.fromJson obsługuje brakujące pola i nieznane wartości', () {
    final monument = Monument.fromJson({
      'id': 2,
      'name': 'Kamienica',
      'category': 'COS_NOWEGO',
      'rarity': null,
      'latitude': 51,
      'longitude': 17,
      'visited': false,
      'visitedAt': null,
    });

    expect(monument.visited, isFalse);
    expect(monument.visitedAt, isNull);
    expect(monument.latitude, 51.0);
    expect(monument.category, MonumentCategory.architektura);
    expect(monument.rarity, Rarity.common);
    expect(monument.visitRadius, 50);
  });

  test('MonumentDetails: opis zablokowany przed wizytą', () {
    final details = MonumentDetails.fromJson({
      'id': 7,
      'name': 'Most Piaskowy',
      'category': 'MOST',
      'rarity': 'EPIC',
      'latitude': 51.11,
      'longitude': 17.04,
      'xp': 65,
      'visitRadius': 75,
      'visited': false,
      'teaser': 'Most · 1861 r.',
      'description': null,
      'descriptionLocked': true,
      'heritageLevel': 'REJESTR',
      'image': {
        'thumbUrl': 'https://upload.wikimedia.org/t.jpg',
        'fullUrl': 'https://upload.wikimedia.org/f.jpg',
        'pageUrl': 'https://commons.wikimedia.org/wiki/File:x.jpg',
      },
      'visitorsCount': 3,
    });

    expect(details.descriptionLocked, isTrue);
    expect(details.description, isNull);
    expect(details.paragraphs, isEmpty);
    expect(details.image?.pageUrl, contains('commons'));
    expect(details.monument.rarity, Rarity.epic);
  });

  test('MonumentDetails: zajawka zawsze, długi opis w akapitach po wizycie', () {
    final details = MonumentDetails.fromJson({
      'id': 9,
      'name': 'Ratusz',
      'category': 'PUBLICZNY',
      'rarity': 'LEGENDARY',
      'isMajor': true,
      'latitude': 51.11,
      'longitude': 17.03,
      'visited': true,
      'teaser': 'Ratusz · XIII wiek',
      'summary': 'Późnogotycki budynek na wrocławskim Rynku.',
      'description': 'Akapit pierwszy.\n\nAkapit drugi.\n\n\nAkapit trzeci.',
      'descriptionLocked': false,
    });

    expect(details.monument.isMajor, isTrue);
    expect(details.summary, startsWith('Późnogotycki'));
    expect(details.paragraphs, ['Akapit pierwszy.', 'Akapit drugi.', 'Akapit trzeci.']);
  });
}
