import 'package:oauth1/oauth1.dart' as oauth1;
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = '1glXeA9Un3z19gDpsmCIf0XE9';
  final apiSecret = '4Ncu0GWmV7UFZo3Iv7fmQM5L8MWtOT3u6Ple66C5tO74BWzB0G';
  final callback = 'https://sociallink.com/oauth-success';

  print('Testing request token...');
  final platform = oauth1.Platform(
    'https://api.twitter.com/oauth/request_token',
    'https://api.twitter.com/oauth/authorize',
    'https://api.twitter.com/oauth/access_token',
    oauth1.SignatureMethods.hmacSha1,
  );

  final clientCredentials = oauth1.ClientCredentials(apiKey, apiSecret);
  final client = oauth1.Client(platform.signatureMethod, clientCredentials, oauth1.Credentials('', ''));

  final url = Uri.parse('https://api.twitter.com/oauth/request_token?oauth_callback=$callback');
  final response = await client.post(url);

  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}
