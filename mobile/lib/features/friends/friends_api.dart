import '../../core/api_client.dart';
import 'models/friend.dart';

class FriendsApi {
  FriendsApi._();
  static final FriendsApi instance = FriendsApi._();

  final _client = ApiClient.instance;

  Future<FriendsOverview> getOverview() async {
    final data = await _client.get('/friends') as Map<String, dynamic>;
    return FriendsOverview.fromJson(data);
  }

  /// Zaproszenie po kodzie (np. "#K7Q2MX" albo "k7q2mx"). Jeśli ta osoba
  /// zaprosiła nas wcześniej, serwer od razu akceptuje znajomość.
  Future<FriendActionResult> addByCode(String code) async {
    final data = await _client.post('/friends', {'code': code.trim()}) as Map<String, dynamic>;
    return FriendActionResult.fromJson(data);
  }

  Future<FriendActionResult> accept(int userId) async {
    final data = await _client.post('/friends/$userId/accept', {}) as Map<String, dynamic>;
    return FriendActionResult.fromJson(data);
  }

  /// Usuwa znajomego, odrzuca zaproszenie albo anuluje wysłane.
  Future<void> remove(int userId) => _client.delete('/friends/$userId');
}
