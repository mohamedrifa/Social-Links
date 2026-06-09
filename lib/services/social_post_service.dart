import '../models/post_model.dart';

abstract class SocialPostService {
  Future<void> publish(
    PostModel post, {
    required String imageUrl,
  });
}