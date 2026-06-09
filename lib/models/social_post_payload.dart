import 'package:image_picker/image_picker.dart';

import 'social_account.dart';

class SocialPostPayload {
  const SocialPostPayload({
    required this.text,
    this.image,
    this.publicImageUrl,
  });

  final String text;
  final XFile? image;

  /// Meta's Instagram and Facebook photo publishing APIs fetch media from a
  /// public HTTPS URL. A local gallery file path cannot be sent directly.
  final String? publicImageUrl;
}

class PlatformPostResult {
  const PlatformPostResult({
    required this.platform,
    required this.success,
    required this.message,
  });

  final SocialPlatform platform;
  final bool success;
  final String message;
}
