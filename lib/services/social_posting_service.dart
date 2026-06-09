import '../models/social_account.dart';
import '../models/social_post_payload.dart';
import 'facebook_service.dart';
import 'instagram_service.dart';
import 'twitter_service.dart';

class SocialPostingService {
  const SocialPostingService({
    required TwitterService twitterService,
    required FacebookService facebookService,
    required InstagramService instagramService,
  })  : _twitterService = twitterService,
        _facebookService = facebookService,
        _instagramService = instagramService;

  final TwitterService _twitterService;
  final FacebookService _facebookService;
  final InstagramService _instagramService;

  Future<List<PlatformPostResult>> postToPlatforms({
    required SocialPostPayload payload,
    required Iterable<SocialPlatform> platforms,
  }) async {
    final results = <PlatformPostResult>[];

    for (final platform in platforms) {
      try {
        switch (platform) {
          case SocialPlatform.twitter:
            await _twitterService.postTweet(payload.text);
            break;
          case SocialPlatform.facebook:
            await _facebookService.publishPost(payload);
            break;
          case SocialPlatform.instagram:
            await _instagramService.publishPost(payload);
            break;
        }

        results.add(
          PlatformPostResult(
            platform: platform,
            success: true,
            message: '${platform.displayName} posted successfully.',
          ),
        );
      } catch (error) {
        results.add(
          PlatformPostResult(
            platform: platform,
            success: false,
            message: error.toString(),
          ),
        );
      }
    }

    return results;
  }
}
