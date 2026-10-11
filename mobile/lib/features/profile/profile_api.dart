import '../../core/api_client.dart';
import 'models/user_profile.dart';

class ProfileApi {
  ProfileApi._();
  static final ProfileApi instance = ProfileApi._();

  final _client = ApiClient.instance;

  Future<UserProfile> getProfile() async {
    final data = await _client.get('/profile') as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  Future<void> selectRank(String rankId) async {
    await _client.patch('/profile/rank', {'rankId': rankId});
  }
}
