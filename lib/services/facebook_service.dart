import 'dart:convert';

import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;

import '../models/social_account.dart';
import '../models/social_post_payload.dart';
import 'oauth_service.dart';

class FacebookService {
  FacebookService({
    required OAuthService oauthService,
    http.Client? httpClient,
  })  : _oauthService = oauthService,
        _httpClient = httpClient ?? http.Client();

  final OAuthService _oauthService;
  final http.Client _httpClient;

  static const graphBaseUrl = String.fromEnvironment(
    'META_GRAPH_BASE_URL',
    defaultValue: 'https://graph.facebook.com/v24.0',
  );
  static const facebookPageId = String.fromEnvironment('FACEBOOK_PAGE_ID');

  Future<SocialAccount?> signIn() async {
    final result = await FacebookAuth.instance.login(
      permissions: const ['public_profile'],
      loginBehavior: LoginBehavior.webOnly,
    );

    if (result.status != LoginStatus.success || result.accessToken == null) {
      if (result.status == LoginStatus.cancelled) {
        return null;
      }

      throw FacebookAuthException(
        result.message ?? 'Facebook login did not complete.',
      );
    }

    final profile = await FacebookAuth.instance.getUserData(
      fields: 'id,name,email,picture.width(200)',
    );

    final picture = profile['picture'] as Map<String, dynamic>?;
    final pictureData = picture?['data'] as Map<String, dynamic>?;
    final accessToken = result.accessToken!.tokenString;

    final account = SocialAccount(
      platform: SocialPlatform.facebook,
      id: profile['id'] as String? ?? '',
      displayName: profile['name'] as String? ?? 'Facebook account',
      email: profile['email'] as String?,
      avatarUrl: pictureData?['url'] as String?,
      connectedAt: DateTime.now(),
    );

    await _oauthService.saveAccount(
      account: account,
      accessToken: accessToken,
    );

    return account;
  }

  Future<SocialAccount?> restoreAccount() {
    return _oauthService.restoreAccount(SocialPlatform.facebook);
  }

  Future<void> publishPost(SocialPostPayload payload) async {
    final text = payload.text.trim();
    if (text.isEmpty && payload.publicImageUrl == null) {
      throw const FacebookAuthException('Add text or a hosted image to post.');
    }

    final accessToken =
        await _oauthService.getAccessToken(SocialPlatform.facebook);
    if (accessToken == null || accessToken.isEmpty) {
      throw const FacebookAuthException('Connect Facebook before posting.');
    }

    if (!await _oauthService.hasValidAccessToken(SocialPlatform.facebook)) {
      throw const FacebookAuthException(
        'Facebook authentication expired. Sign in again.',
      );
    }

    if (facebookPageId.isEmpty) {
      throw const FacebookAuthException(
        'Missing FACEBOOK_PAGE_ID. Facebook posting requires a Page ID.',
      );
    }

    final endpoint = payload.publicImageUrl == null
        ? '$graphBaseUrl/$facebookPageId/feed'
        : '$graphBaseUrl/$facebookPageId/photos';
    final body = <String, String>{
      'access_token': accessToken,
      if (text.isNotEmpty) 'message': text,
      if (payload.publicImageUrl != null) 'url': payload.publicImageUrl!,
    };

    final response = await _httpClient.post(Uri.parse(endpoint), body: body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FacebookAuthException(_readGraphError(response));
    }
  }

  Future<void> signOut() async {
    await FacebookAuth.instance.logOut();
    await _oauthService.clearAccount(SocialPlatform.facebook);
  }

  Future<String?> getPageAccessToken() async {
    final userAccessToken =
        await _oauthService.getAccessToken(SocialPlatform.facebook);
    if (userAccessToken == null || userAccessToken.isEmpty) {
      return null;
    }

    return _resolvePublishingAccessToken(userAccessToken);
  }

  Future<void> requestPublishingPermissions() async {
    final result = await FacebookAuth.instance.login(
      permissions: const [
        'pages_show_list',
        'pages_read_engagement',
        'pages_manage_posts',
        'instagram_basic',
        'instagram_content_publish',
      ],
      loginBehavior: LoginBehavior.webOnly,
    );

    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw FacebookAuthException(
        result.message ?? 'Meta publishing permissions were not granted.',
      );
    }

    final storedAccount =
        await _oauthService.restoreStoredAccount(SocialPlatform.facebook);
    if (storedAccount == null) {
      return;
    }

    final pageToken = await _resolvePublishingAccessToken(
      result.accessToken!.tokenString,
    );

    await _oauthService.saveAccount(
      account: storedAccount,
      accessToken: pageToken,
    );
  }

  Future<String> _resolvePublishingAccessToken(String userAccessToken) async {
    if (facebookPageId.isEmpty) {
      return userAccessToken;
    }

    final response = await _httpClient.get(
      Uri.parse('$graphBaseUrl/me/accounts').replace(
        queryParameters: {'access_token': userAccessToken},
      ),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return userAccessToken;
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final pages = decoded['data'] as List<dynamic>? ?? [];
      for (final page in pages) {
        final pageMap = page as Map<String, dynamic>;
        if (pageMap['id'] == facebookPageId) {
          final pageToken = pageMap['access_token'] as String?;
          if (pageToken != null && pageToken.isNotEmpty) {
            return pageToken;
          }
        }
      }
    } catch (_) {
      return userAccessToken;
    }

    return userAccessToken;
  }

  String _readGraphError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final error = decoded['error'] as Map<String, dynamic>?;
      final message = error?['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    } catch (_) {
      // Fall through to a status-code based message.
    }

    return 'Facebook request failed with status ${response.statusCode}.';
  }
}

class FacebookAuthException implements Exception {
  const FacebookAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
