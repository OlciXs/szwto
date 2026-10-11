import '../../core/api_client.dart';

class AuthApi {
  AuthApi._();
  static final AuthApi instance = AuthApi._();

  final _client = ApiClient.instance;

  Future<void> login(String email, String password) =>
      _authenticate('/auth/login', {
        'email': email.trim(),
        'password': password,
      });

  /// [displayName] jest opcjonalny – backend wygeneruje go z adresu e-mail.
  Future<void> register(String email, String password, {String? displayName}) =>
      _authenticate('/auth/register', {
        'email': email.trim(),
        'password': password,
        if (displayName != null && displayName.trim().isNotEmpty)
          'displayName': displayName.trim(),
      });

  Future<void> _authenticate(String path, Map<String, String> body) async {
    final data = await _client.post(path, body) as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    final email = user['email'] as String;
    await _client.saveSession(
      token: data['accessToken'] as String,
      email: email,
      // starszy backend nie zwraca displayName
      displayName: user['displayName'] as String? ?? email.split('@').first,
    );
  }
}
