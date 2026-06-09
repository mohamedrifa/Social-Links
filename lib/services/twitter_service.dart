import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;

import '../models/social_account.dart';
import 'oauth_service.dart';

class TwitterService {
  TwitterService({
    required OAuthService oauthService,
    FlutterAppAuth? appAuth,
    http.Client? httpClient,
  })  : _oauthService = oauthService,
        _appAuth = appAuth ?? FlutterAppAuth(),
        _httpClient = httpClient ?? http.Client();

  final OAuthService _oauthService;
  final FlutterAppAuth _appAuth;
  final http.Client _httpClient;

  static const _authorizationEndpoint = 'https://x.com/i/oauth2/authorize';
  static const _tokenEndpoint = 'https://api.x.com/2/oauth2/token';
  static const _tweetEndpoint = 'https://api.x.com/2/tweets';
  static const _meEndpoint =
      'https://api.x.com/2/users/me?user.fields=profile_image_url,username';
  static const _loginTimeout = Duration(seconds: 90);
  static const _baseScopes = [
    'tweet.read',
    'tweet.write',
    'users.read',
  ];

  Future<SocialAccount?> signIn() async {
    if (OAuthService.twitterClientId.isEmpty) {
      throw const AuthConfigurationException(
        'Missing TWITTER_CLIENT_ID. Pass it with --dart-define.',
      );
    }
    if (!OAuthService.twitterRedirectUrl.startsWith('sociallink://')) {
      throw const AuthConfigurationException(
        'TWITTER_REDIRECT_URL must start with sociallink:// for the current native app configuration.',
      );
    }

    final result = await _appAuth
        .authorizeAndExchangeCode(
          AuthorizationTokenRequest(
            OAuthService.twitterClientId,
            OAuthService.twitterRedirectUrl,
            serviceConfiguration: AuthorizationServiceConfiguration(
              authorizationEndpoint: _authorizationEndpoint,
              tokenEndpoint: _tokenEndpoint,
            ),
            scopes: [
              ..._baseScopes,
              if (OAuthService.twitterUseOfflineAccess) 'offline.access',
            ],
            promptValues: const ['consent'],
          ),
        )
        .timeout(
          _loginTimeout,
          onTimeout: () => throw const AuthConfigurationException(
            'X login timed out. Check that the callback URL in the X developer portal exactly matches TWITTER_REDIRECT_URL.',
          ),
        );

    final accessToken = result.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw const AuthConfigurationException('X did not return an access token.');
    }

    final account = await _fetchCurrentUser(accessToken);
    await _oauthService.saveAccount(
      account: account,
      accessToken: accessToken,
      refreshToken: result.refreshToken,
      tokenExpiresAt: result.accessTokenExpirationDateTime,
    );

    return account;
  }

  Future<SocialAccount?> restoreAccount() {
    return _oauthService.restoreAccount(SocialPlatform.twitter);
  }

  Future<void> signOut() {
    return _oauthService.clearAccount(SocialPlatform.twitter);
  }

  Future<void> postTweet(String text) async {
    final content = text.trim();
    if (content.isEmpty) {
      throw const SocialPostException('Write something before posting.');
    }

    final accessToken = await _getValidAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const SocialPostException('Connect your X account before posting.');
    }

    final response = await _httpClient.post(
      Uri.parse(_tweetEndpoint),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'text': content}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SocialPostException(_readApiError(response));
    }
  }

  Future<String?> _getValidAccessToken() async {
    if (await _oauthService.hasValidAccessToken(SocialPlatform.twitter)) {
      return _oauthService.getAccessToken(SocialPlatform.twitter);
    }

    final refreshToken =
        await _oauthService.getRefreshToken(SocialPlatform.twitter);
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final result = await _appAuth.token(
      TokenRequest(
        OAuthService.twitterClientId,
        OAuthService.twitterRedirectUrl,
        refreshToken: refreshToken,
        serviceConfiguration: AuthorizationServiceConfiguration(
          authorizationEndpoint: _authorizationEndpoint,
          tokenEndpoint: _tokenEndpoint,
        ),
        scopes: [
          ..._baseScopes,
          if (OAuthService.twitterUseOfflineAccess) 'offline.access',
        ],
      ),
    );

    final refreshedToken = result.accessToken;
    if (refreshedToken == null || refreshedToken.isEmpty) {
      return null;
    }

    final restoredAccount =
        await _oauthService.restoreStoredAccount(SocialPlatform.twitter);
    if (restoredAccount != null) {
      await _oauthService.saveAccount(
        account: restoredAccount,
        accessToken: refreshedToken,
        refreshToken: result.refreshToken ?? refreshToken,
        tokenExpiresAt: result.accessTokenExpirationDateTime,
      );
    }

    return refreshedToken;
  }

  Future<SocialAccount> _fetchCurrentUser(String accessToken) async {
    final response = await _httpClient.get(
      Uri.parse(_meEndpoint),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SocialPostException(_readApiError(response));
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>? ?? {};

    return SocialAccount(
      platform: SocialPlatform.twitter,
      id: data['id'] as String? ?? '',
      displayName: data['name'] as String? ?? 'X account',
      username: data['username'] as String?,
      avatarUrl: data['profile_image_url'] as String?,
      connectedAt: DateTime.now(),
    );
  }

  String _readApiError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final title = decoded['title'];
      final type = decoded['type'];
      if (title == 'CreditsDepleted' ||
          (type is String && type.contains('/problems/credits'))) {
        return 'Your X API account has no credits for this request. Add credits or enable billing in the X Developer Portal, then try again.';
      }

      final detail = decoded['detail'] ?? decoded['title'] ?? decoded['error'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    } catch (_) {
      // Fall through to a status-code based error.
    }

    return 'X request failed with status ${response.statusCode}.';
  }
}

class AuthConfigurationException implements Exception {
  const AuthConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SocialPostException implements Exception {
  const SocialPostException(this.message);

  final String message;

  @override
  String toString() => message;
}
