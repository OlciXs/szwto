import '../../core/api_client.dart';
import '../../core/models/monument_category.dart';
import 'models/monument.dart';

class MonumentsApi {
  MonumentsApi._();
  static final MonumentsApi instance = MonumentsApi._();

  final _client = ApiClient.instance;

  Future<List<Monument>> getMonuments({MonumentCategory? category}) async {
    final query = category == null ? '' : '?category=${category.apiValue}';
    final data = await _client.get('/monuments$query') as List<dynamic>;
    return data
        .map((item) => Monument.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MonumentDetails> getMonument(int id) async {
    final data = await _client.get('/monuments/$id') as Map<String, dynamic>;
    return MonumentDetails.fromJson(data);
  }

  Future<VisitResult> visitMonument(
    int monumentId,
    double latitude,
    double longitude,
  ) async {
    final data = await _client.post(
      '/monuments/$monumentId/visit',
      {'latitude': latitude, 'longitude': longitude},
    ) as Map<String, dynamic>;
    return VisitResult.fromJson(data);
  }
}
