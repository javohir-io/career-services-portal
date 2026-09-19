import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _client = ApiClient.instance;

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    String? university,
    String? phone,
  }) async {
    final data = await _client.post('/api/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      if (university != null) 'university': university,
      if (phone != null) 'phone': phone,
    });
    await _client.saveToken(data['token'] as String);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.post('/api/auth/login', body: {
      'email': email,
      'password': password,
    });
    await _client.saveToken(data['token'] as String);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> fetchMe() async {
    final data = await _client.get('/api/auth/me');
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> updateProfile({
    String? name,
    String? university,
    String? degreeProgram,
    String? phone,
    String? about,
  }) async {
    final data = await _client.put('/api/auth/me', body: {
      if (name != null) 'name': name,
      if (university != null) 'university': university,
      if (degreeProgram != null) 'degreeProgram': degreeProgram,
      if (phone != null) 'phone': phone,
      if (about != null) 'about': about,
    });
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> uploadProfilePhoto({
    required List<int> bytes,
    required String fileName,
  }) async {
    final data = await _client.postMultipart(
      '/api/auth/me/photo',
      fields: const {},
      fileFieldName: 'photo',
      bytes: bytes,
      fileName: fileName,
    );
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() => _client.clearToken();

  Future<bool> get isLoggedIn async => (await _client.token) != null;
}
