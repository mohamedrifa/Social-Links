import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oauth1/oauth1.dart' as oauth1;

class ApiService {
  // Twitter API credentials
  static const String _twitterApiKey = 'AdexQuC7VSmdsXUt5qLoEyNlG';
  static const String _twitterApiSecret = 'h3uMz8eckU17WQC2lxhswCKgd7g2aoTcx1EZWypSjIDUQnxqd4';

  Future<bool> postToFacebook(String token, String message) async {
    try {
      final url = Uri.parse('https://graph.facebook.com/me/feed');
      final response = await http.post(
        url,
        body: {
          'message': message,
          'access_token': token,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> postToTwitter(String token, String secret, String message) async {
    try {
      final platform = oauth1.Platform(
        'https://api.twitter.com/oauth/request_token',
        'https://api.twitter.com/oauth/authorize',
        'https://api.twitter.com/oauth/access_token',
        oauth1.SignatureMethods.hmacSha1,
      );

      final clientCredentials = oauth1.ClientCredentials(_twitterApiKey, _twitterApiSecret);
      final client = oauth1.Client(platform.signatureMethod, clientCredentials, oauth1.Credentials(token, secret));

      // Upgraded to API v2 endpoint for posting
      final url = Uri.parse('https://api.twitter.com/2/tweets');
      
      // We must post JSON to API v2
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': message}),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
