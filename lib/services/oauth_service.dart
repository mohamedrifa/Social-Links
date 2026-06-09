import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/social_account.dart';

class OAuthService {
  OAuthService({FlutterSecureStorage? secureStorage})
      : _storage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const twitterClientId = String.fromEnvironment('TWITTER_CLIENT_ID');
  static const twitterRedirectUrl = String.fromEnvironment(
    'TWITTER_REDIRECT_URL',
    defaultValue: 'sociallink://oauth2redirect',
  );
  static const twitterUseOfflineAccess = bool.fromEnvironment(
    'TWITTER_USE_OFFLINE_ACCESS',
  );

  static const _accountPrefix = 'social_account';
  static const _accessTokenPrefix = 'access_token';
  static const _refreshTokenPrefix = 'refresh_token';
  static const _tokenExpiresAtPrefix = 'token_expires_at';

  Future<void> saveAccount({
    required SocialAccount account,
    required String accessToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
  }) async {
    final platform = account.platform.storageKey;
    await _write(
      key: '$_accountPrefix.$platform',
      value: account.toJson(),
    );
    await _write(
      key: '$_accessTokenPrefix.$platform',
      value: accessToken,
    );

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _write(
        key: '$_refreshTokenPrefix.$platform',
        value: refreshToken,
      );
    }

    if (tokenExpiresAt != null) {
      await _write(
        key: '$_tokenExpiresAtPrefix.$platform',
        value: tokenExpiresAt.toIso8601String(),
      );
    }
  }

  Future<SocialAccount?> restoreAccount(SocialPlatform platform) async {
    final rawAccount =
        await _read(key: '$_accountPrefix.${platform.storageKey}');
    final accessToken = await getAccessToken(platform);
    final hasValidToken = await hasValidAccessToken(platform);

    if (rawAccount == null ||
        accessToken == null ||
        accessToken.isEmpty ||
        !hasValidToken) {
      return null;
    }

    try {
      return SocialAccount.fromJson(rawAccount);
    } catch (_) {
      await clearAccount(platform);
      return null;
    }
  }

  Future<SocialAccount?> restoreStoredAccount(SocialPlatform platform) async {
    final rawAccount =
        await _read(key: '$_accountPrefix.${platform.storageKey}');
    if (rawAccount == null) {
      return null;
    }

    try {
      return SocialAccount.fromJson(rawAccount);
    } catch (_) {
      await clearAccount(platform);
      return null;
    }
  }

  Future<String?> getAccessToken(SocialPlatform platform) {
    return _read(key: '$_accessTokenPrefix.${platform.storageKey}');
  }

  Future<String?> getRefreshToken(SocialPlatform platform) {
    return _read(key: '$_refreshTokenPrefix.${platform.storageKey}');
  }

  Future<bool> hasValidAccessToken(SocialPlatform platform) async {
    final token = await getAccessToken(platform);
    if (token == null || token.isEmpty) {
      return false;
    }

    final rawExpiresAt =
        await _read(key: '$_tokenExpiresAtPrefix.${platform.storageKey}');
    if (rawExpiresAt == null || rawExpiresAt.isEmpty) {
      return true;
    }

    final expiresAt = DateTime.tryParse(rawExpiresAt);
    if (expiresAt == null) {
      return true;
    }

    return expiresAt.isAfter(DateTime.now().add(const Duration(minutes: 2)));
  }

  Future<void> clearAccount(SocialPlatform platform) async {
    final platformKey = platform.storageKey;
    await _delete(key: '$_accountPrefix.$platformKey');
    await _delete(key: '$_accessTokenPrefix.$platformKey');
    await _delete(key: '$_refreshTokenPrefix.$platformKey');
    await _delete(key: '$_tokenExpiresAtPrefix.$platformKey');
  }

  Future<String?> _read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> _write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } on MissingPluginException catch (error) {
      throw SecureStorageUnavailableException(error.message);
    }
  }

  Future<void> _delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } on MissingPluginException {
      return;
    }
  }
}

class SecureStorageUnavailableException implements Exception {
  const SecureStorageUnavailableException(this.message);

  final String? message;

  @override
  String toString() {
    return 'Secure storage is not available in this app build. Stop the app and rebuild it.';
  }
}
