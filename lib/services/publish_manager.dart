import '../models/post_model.dart';
import 'facebook_service.dart';
import 'instagram_service.dart';
import 'telegram_service.dart';

class PublishManager {
  final FacebookService facebookService;
  final InstagramService instagramService;
  final TelegramService telegramService;

  PublishManager({
    required this.facebookService,
    required this.instagramService,
    required this.telegramService,
  });

  Future<void> publishPost({
    required PostModel post,
    required String imageUrl,
  }) async {
    for (final platform in post.platforms) {
      switch (platform) {
        case 'facebook':
          await facebookService.publish(
            post,
            imageUrl: imageUrl,
          );
          break;

        case 'instagram':
          await instagramService.publish(
            post,
            imageUrl: imageUrl,
          );
          break;

        case 'telegram':
          await telegramService.publish(
            post,
            imageUrl: imageUrl,
          );
          break;
      }
    }
  }
}