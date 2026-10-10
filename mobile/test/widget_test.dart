import 'package:flutter_test/flutter_test.dart';
import 'package:zabytki_app/models/monument.dart';

void main() {
  test('Monument.fromJson poprawnie parsuje odpowiedź API', () {
    final monument = Monument.fromJson({
      'id': 1,
      'name': 'Zamek Królewski na Wawelu',
      'description': 'Zamek w Krakowie',
      'latitude': 50.054,
      'longitude': 19.9354,
      'visited': true,
      'visitedAt': '2026-10-10T12:00:00.000Z',
    });

    expect(monument.id, 1);
    expect(monument.visited, isTrue);
    expect(monument.visitedAt, isNotNull);
    expect(monument.latitude, closeTo(50.054, 1e-9));
  });

  test('Monument.fromJson obsługuje nieodwiedzony zabytek', () {
    final monument = Monument.fromJson({
      'id': 2,
      'name': 'Sukiennice',
      'description': 'Rynek Główny',
      'latitude': 50,
      'longitude': 19,
      'visited': false,
      'visitedAt': null,
    });

    expect(monument.visited, isFalse);
    expect(monument.visitedAt, isNull);
    expect(monument.latitude, 50.0);
  });
}
