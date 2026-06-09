import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/social_account.dart';
import '../models/social_post_payload.dart';
import 'oauth_service.dart';

class InstagramService {
  InstagramService({
    required OAuthService oauthService,
    Future<String?> Function()? pageAccessTokenProvider,
    http.Client? httpClient,
  })  : _oauthService = oauthService,
        _pageAccessTokenProvider = pageAccessTokenProvider,
        _httpClient = httpClient ?? http.Client();

  final OAuthService _oauthService;
  final Future<String?> Function()? _pageAccessTokenProvider;
  final http.Client _httpClient;

  static const graphBaseUrl = String.fromEnvironment(
    'META_GRAPH_BASE_URL',
    defaultValue: 'https://graph.facebook.com/v24.0',
  );
  static const instagramBusinessAccountId =
      String.fromEnvironment('INSTAGRAM_BUSINESS_ACCOUNT_ID');
  static const facebookPageId = String.fromEnvironment('FACEBOOK_PAGE_ID');

  Future<SocialAccount?> restoreAccount() {
    return _oauthService.restoreAccount(SocialPlatform.instagram);
  }

  Future<void> connectFromFacebookAccount() async {
    final accessToken = await _resolveMetaAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    final account = instagramBusinessAccountId.isNotEmpty
        ? SocialAccount(
            platform: SocialPlatform.instagram,
            id: instagramBusinessAccountId,
            displayName: 'Instagram business account',
            connectedAt: DateTime.now(),
          )
        : await _discoverInstagramAccount(accessToken);

    if (account == null) {
      return;
    }

    await _oauthService.saveAccount(
      account: account,
      accessToken: accessToken,
    );
  }

  Future<void> publishPost(SocialPostPayload payload) async {
    final caption = payload.text.trim();
    final imageUrl = payload.publicImageUrl;

    final account = await _oauthService.restoreStoredAccount(
      SocialPlatform.instagram,
    );
    final accountId = instagramBusinessAccountId.isNotEmpty
        ? instagramBusinessAccountId
        : account?.id;

    if (accountId == null || accountId.isEmpty) {
      throw const InstagramPostException(
        'Connect Instagram from Accounts before posting.',
      );
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      throw const InstagramPostException(
        'Instagram Graph API requires a publicly accessible HTTPS image URL.',
      );
    }

    final accessToken =
        await _oauthService.getAccessToken(SocialPlatform.instagram) ??
            await _oauthService.getAccessToken(SocialPlatform.facebook);
    if (accessToken == null || accessToken.isEmpty) {
      throw const InstagramPostException('Connect Instagram before posting.');
    }

    final createResponse = await _httpClient.post(
      Uri.parse('$graphBaseUrl/$accountId/media'),
      body: {
        'image_url': imageUrl,
        if (caption.isNotEmpty) 'caption': caption,
        'access_token': accessToken,
      },
    );

    if (createResponse.statusCode < 200 || createResponse.statusCode >= 300) {
      throw InstagramPostException(_readGraphError(createResponse));
    }

    final createBody = jsonDecode(createResponse.body) as Map<String, dynamic>;
    final creationId = createBody['id'] as String?;
    if (creationId == null || creationId.isEmpty) {
      throw const InstagramPostException(
        'Instagram did not return a media creation ID.',
      );
    }

    final publishResponse = await _httpClient.post(
      Uri.parse('$graphBaseUrl/$accountId/media_publish'),
      body: {
        'creation_id': creationId,
        'access_token': accessToken,
      },
    );

    if (publishResponse.statusCode < 200 ||
        publishResponse.statusCode >= 300) {
      throw InstagramPostException(_readGraphError(publishResponse));
    }
  }

  Future<void> signOut() {
    return _oauthService.clearAccount(SocialPlatform.instagram);
  }

  Future<String?> _resolveMetaAccessToken() async {
    final pageToken = await _pageAccessTokenProvider?.call();
    if (pageToken != null && pageToken.isNotEmpty) {
      return pageToken;
    }

    return _oauthService.getAccessToken(SocialPlatform.facebook);
  }

  Future<SocialAccount?> _discoverInstagramAccount(String accessToken) async {
    if (facebookPageId.isEmpty) {
      throw const InstagramPostException(
        'Missing FACEBOOK_PAGE_ID. Add your Facebook Page ID to discover Instagram.',
      );
    }

    final response = await _httpClient.get(
      Uri.parse('$graphBaseUrl/$facebookPageId').replace(
        queryParameters: {
          'fields': 'instagram_business_account{id,username,name,profile_picture_url}',
          'access_token': accessToken,
        },
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InstagramPostException(_readGraphError(response));
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final instagram =
        decoded['instagram_business_account'] as Map<String, dynamic>?;
    if (instagram == null) {
      throw const InstagramPostException(
        'No Instagram professional account is connected to this Facebook Page.',
      );
    }

    return SocialAccount(
      platform: SocialPlatform.instagram,
      id: instagram['id'] as String? ?? '',
      displayName:
          instagram['name'] as String? ?? instagram['username'] as String? ??
              'Instagram business account',
      username: instagram['username'] as String?,
      avatarUrl: instagram['profile_picture_url'] as String?,
      connectedAt: DateTime.now(),
    );
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

    return 'Instagram request failed with status ${response.statusCode}.';
  }
}

class InstagramPostException implements Exception {
  const InstagramPostException(this.message);

  final String message;

  @override
  String toString() => message;
}
