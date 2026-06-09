import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/social_account.dart';
import '../models/social_post_payload.dart';
import 'oauth_service.dart';

class InstagramService {
  InstagramService({
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
  static const instagramBusinessAccountId =
      String.fromEnvironment('INSTAGRAM_BUSINESS_ACCOUNT_ID');

  Future<SocialAccount?> restoreAccount() {
    return _oauthService.restoreAccount(SocialPlatform.instagram);
  }

  Future<void> connectFromFacebookAccount() async {
    final facebookToken =
        await _oauthService.getAccessToken(SocialPlatform.facebook);
    if (facebookToken == null || facebookToken.isEmpty) {
      return;
    }

    if (instagramBusinessAccountId.isEmpty) {
      return;
    }

    await _oauthService.saveAccount(
      account: SocialAccount(
        platform: SocialPlatform.instagram,
        id: instagramBusinessAccountId,
        displayName: 'Instagram business account',
        connectedAt: DateTime.now(),
      ),
      accessToken: facebookToken,
    );
  }

  Future<void> publishPost(SocialPostPayload payload) async {
    final caption = payload.text.trim();
    final imageUrl = payload.publicImageUrl;

    if (instagramBusinessAccountId.isEmpty) {
      throw const InstagramPostException(
        'Missing INSTAGRAM_BUSINESS_ACCOUNT_ID.',
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
      Uri.parse('$graphBaseUrl/$instagramBusinessAccountId/media'),
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
      Uri.parse('$graphBaseUrl/$instagramBusinessAccountId/media_publish'),
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
