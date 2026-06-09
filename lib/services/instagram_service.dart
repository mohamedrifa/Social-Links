import 'package:dio/dio.dart';

import '../models/post_model.dart';
import 'social_post_service.dart';

class InstagramService implements SocialPostService {
  final Dio dio;

  final String instagramBusinessId;
  final String accessToken;

  InstagramService({
    required this.dio,
    required this.instagramBusinessId,
    required this.accessToken,
  });

  @override
  Future<void> publish(
    PostModel post, {
    required String imageUrl,
  }) async {
    final containerResponse = await dio.post(
      'https://graph.facebook.com/v25.0/$instagramBusinessId/media',
      data: {
        'image_url': imageUrl,
        'caption': post.description,
        'access_token': accessToken,
      },
    );

    final creationId = containerResponse.data['id'];

    await dio.post(
      'https://graph.facebook.com/v25.0/$instagramBusinessId/media_publish',
      data: {
        'creation_id': creationId,
        'access_token': accessToken,
      },
    );
  }
}