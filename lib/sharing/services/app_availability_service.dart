import 'package:flutter/services.dart';

import '../models/share_platform.dart';

class AppAvailabilityService {
  static const _channel = MethodChannel('social_link/app_availability');

  Future<List<SharePlatform>> installedPlatforms() async {
    try {
      final ids = await _channel.invokeListMethod<String>(
        'getInstalledPlatforms',
      );
      final platforms = (ids ?? [])
          .map((id) => SharePlatformInfo.fromId(id))
          .whereType<SharePlatform>()
          .toSet()
          .toList();

      platforms.sort((a, b) => a.index.compareTo(b.index));
      return platforms;
    } on MissingPluginException {
      return const [SharePlatform.email];
    } on PlatformException {
      return const [SharePlatform.email];
    }
  }
}
