import '../../core/api_client.dart';
import '../achievements/models/achievement.dart';
import 'models/comment.dart';

class CommentsApi {
  CommentsApi._();
  static final CommentsApi instance = CommentsApi._();

  final _client = ApiClient.instance;

  Future<CommentsPage> getComments(int monumentId, {int? before}) async {
    final query = before == null ? '' : '?before=$before';
    final data = await _client.get('/monuments/$monumentId/comments$query')
        as Map<String, dynamic>;
    return CommentsPage.fromJson(data);
  }

  /// Dodaje komentarz – serwer sprawdza wizytę i to, czy gracz jest na miejscu.
  Future<Rewards> addComment(
    int monumentId,
    String body,
    double latitude,
    double longitude,
  ) async {
    final data = await _client.post('/monuments/$monumentId/comments', {
      'body': body,
      'latitude': latitude,
      'longitude': longitude,
    }) as Map<String, dynamic>;
    return Rewards.fromJson(data['rewards'] as Map<String, dynamic>? ?? const {});
  }

  Future<void> deleteComment(int commentId) => _client.delete('/comments/$commentId');
}
