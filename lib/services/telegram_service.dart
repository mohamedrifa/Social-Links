import 'package:dio/dio.dart';

import '../models/post_model.dart';
import 'social_post_service.dart';

class TelegramService implements SocialPostService {
  final Dio dio;

  final String botToken;
  final String chatId;

  TelegramService({
    required this.dio,
    required this.botToken,
    required this.chatId,
  });

  @override
  Future<void> publish(
    PostModel post, {
    required String imageUrl,
  }) async {
    await dio.post(
      'https://api.telegram.org/bot$botToken/sendPhoto',
      data: {
        'chat_id': chatId,
        'photo': imageUrl,
        'caption': post.description,
      },
    );
  }
}