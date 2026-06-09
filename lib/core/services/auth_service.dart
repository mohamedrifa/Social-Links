import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:twitter_login/twitter_login.dart';

class AuthService {
  // Twitter OAuth 1.0a credentials
  static const String _twitterApiKey = 'c3fV5HzuwmFc1E7tvMhOuzKoN';
  static const String _twitterApiSecret = 'cXrntHQO1iYIc9qlYXgRZOAC1vZ2AJ3ciFjFm9Zyvj22l677m8';
  static const String _twitterCallbackUrl = 'https://sociallink.com/oauth-success';

  Future<String?> loginWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login(permissions: ['public_profile', 'email']);
    
    if (result.status == LoginStatus.success) {
      final AccessToken accessToken = result.accessToken!;
      return accessToken.tokenString;
    } else {
      debugPrint('Facebook login failed: ${result.message}');
      return null;
    }
  }

  Future<void> logoutFacebook() async {
    await FacebookAuth.instance.logOut();
  }

  Future<Map<String, String>?> loginWithTwitter() async {
    final twitterLogin = TwitterLogin(
      apiKey: _twitterApiKey,
      apiSecretKey: _twitterApiSecret,
      redirectURI: _twitterCallbackUrl,
    );

    final authResult = await twitterLogin.login();
    
    switch (authResult.status) {
      case TwitterLoginStatus.loggedIn:
        return {
          'token': authResult.authToken!,
          'secret': authResult.authTokenSecret!,
        };
      case TwitterLoginStatus.cancelledByUser:
        throw Exception('Login cancelled by user');
      case TwitterLoginStatus.error:
        throw Exception(authResult.errorMessage ?? 'Unknown login error');
      default:
        throw Exception('Unexpected status');
    }
  }
}
