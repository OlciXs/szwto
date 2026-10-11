import '../../core/api_client.dart';
import '../achievements/models/achievement.dart';
import 'models/showcase.dart';

class ShowcaseApi {
  ShowcaseApi._();
  static final ShowcaseApi instance = ShowcaseApi._();

  final _client = ApiClient.instance;

  /// Wystawia zabytek w miejscu [slot]. Zwraca gablotkę i nagrody (np. „Kurator”).
  Future<(Showcase, Rewards)> setSlot(int slot, int monumentId) async {
    final data = await _client.put('/showcase/$slot', {'monumentId': monumentId})
        as Map<String, dynamic>;
    return (
      Showcase.fromJson(data['showcase'] as Map<String, dynamic>),
      Rewards.fromJson(data['rewards'] as Map<String, dynamic>? ?? const {}),
    );
  }

  Future<Showcase> clearSlot(int slot) async {
    final data = await _client.delete('/showcase/$slot') as Map<String, dynamic>;
    return Showcase.fromJson(data['showcase'] as Map<String, dynamic>);
  }
}
