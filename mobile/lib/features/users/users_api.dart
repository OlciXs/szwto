import '../../core/api_client.dart';
import 'models/public_profile.dart';

class UsersApi {
  UsersApi._();
  static final UsersApi instance = UsersApi._();

  final _client = ApiClient.instance;

  Future<PublicProfile> getProfile(int userId) async {
    final data = await _client.get('/users/$userId') as Map<String, dynamic>;
    return PublicProfile.fromJson(data);
  }

  /// [friendsOnly] – ranking tylko wśród znajomych (i mnie).
  Future<Leaderboard> getLeaderboard({bool friendsOnly = false}) async {
    final path = friendsOnly ? '/users/leaderboard?scope=friends' : '/users/leaderboard';
    final data = await _client.get(path) as Map<String, dynamic>;
    return Leaderboard.fromJson(data);
  }

  /// Zmienia nazwę gracza i aktualizuje ją w zapisanej sesji.
  Future<String> updateDisplayName(String displayName) async {
    final data = await _client.patch('/users/me', {'displayName': displayName.trim()})
        as Map<String, dynamic>;
    final name = data['displayName'] as String;
    await _client.updateDisplayName(name);
    return name;
  }
}
