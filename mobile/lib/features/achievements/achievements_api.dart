import '../../core/api_client.dart';
import 'models/achievement.dart';
import 'models/progression.dart';

class AchievementsList {
  final int unlockedCount;
  final int total;
  final List<Achievement> achievements;

  AchievementsList({
    required this.unlockedCount,
    required this.total,
    required this.achievements,
  });
}

class AchievementsApi {
  AchievementsApi._();
  static final AchievementsApi instance = AchievementsApi._();

  final _client = ApiClient.instance;

  Future<Progression> getProgression() async {
    final data = await _client.get('/progression') as Map<String, dynamic>;
    return Progression.fromJson(data);
  }

  Future<AchievementsList> getAchievements() async {
    final data = await _client.get('/achievements') as Map<String, dynamic>;
    return AchievementsList(
      unlockedCount: data['unlockedCount'] as int? ?? 0,
      total: data['total'] as int? ?? 0,
      achievements: (data['achievements'] as List<dynamic>)
          .map((a) => Achievement.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Zgłasza otwarcie artykułu na Wikipedii – może odblokować „Mola książkowego”.
  Future<Rewards> wikipediaOpened(int monumentId) async {
    final data = await _client.post('/events', {
      'type': 'WIKIPEDIA_OPENED',
      'monumentId': monumentId,
    }) as Map<String, dynamic>;
    return Rewards.fromJson(data['rewards'] as Map<String, dynamic>? ?? const {});
  }
}
