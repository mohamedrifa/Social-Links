import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _keyFbToken = 'fbAuthToken';
  static const _keyTwToken = 'tweetAuthToken';
  static const _keyTwSecret = 'tweetAuthSecret';

  Future<void> saveFbToken(String token) async {
    await _storage.write(key: _keyFbToken, value: token);
  }

  Future<String?> getFbToken() async {
    return await _storage.read(key: _keyFbToken);
  }

  Future<void> clearFbToken() async {
    await _storage.delete(key: _keyFbToken);
  }

  Future<void> saveTwitterToken(String token, String secret) async {
    await _storage.write(key: _keyTwToken, value: token);
    await _storage.write(key: _keyTwSecret, value: secret);
  }

  Future<Map<String, String>?> getTwitterToken() async {
    final token = await _storage.read(key: _keyTwToken);
    final secret = await _storage.read(key: _keyTwSecret);
    if (token != null && secret != null) {
      return {'token': token, 'secret': secret};
    }
    return null;
  }

  Future<void> clearTwitterToken() async {
    await _storage.delete(key: _keyTwToken);
    await _storage.delete(key: _keyTwSecret);
  }
}
