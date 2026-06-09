import 'package:dio/dio.dart';

import '../models/post_model.dart';
import 'social_post_service.dart';

class FacebookService implements SocialPostService {
  final Dio dio;

  final String pageId;
  final String accessToken;

  FacebookService({
    required this.dio,
    required this.pageId,
    required this.accessToken,
  });

  @override
  Future<void> publish(
    PostModel post, {
    required String imageUrl,
  }) async {
    await dio.post(
      'https://graph.facebook.com/v25.0/$pageId/photos',
      data: {
        'url': imageUrl,
        'caption': post.description,
        'access_token': accessToken,
      },
    );
  }
}