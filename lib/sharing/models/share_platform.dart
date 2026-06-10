import 'package:flutter/material.dart';

enum SharePlatform {
  facebook,
  twitter,
  instagram,
  whatsapp,
  telegram,
  linkedin,
  pinterest,
  tiktok,
  snapchat,
  reddit,
  youtube,
  wechat,
  email,
}

extension SharePlatformInfo on SharePlatform {
  String get id => switch (this) {
        SharePlatform.facebook => 'facebook',
        SharePlatform.twitter => 'twitter',
        SharePlatform.instagram => 'instagram',
        SharePlatform.whatsapp => 'whatsapp',
        SharePlatform.telegram => 'telegram',
        SharePlatform.linkedin => 'linkedin',
        SharePlatform.pinterest => 'pinterest',
        SharePlatform.tiktok => 'tiktok',
        SharePlatform.snapchat => 'snapchat',
        SharePlatform.reddit => 'reddit',
        SharePlatform.youtube => 'youtube',
        SharePlatform.wechat => 'wechat',
        SharePlatform.email => 'email',
      };

  String get label => switch (this) {
        SharePlatform.facebook => 'Facebook',
        SharePlatform.twitter => 'X',
        SharePlatform.instagram => 'Instagram',
        SharePlatform.whatsapp => 'WhatsApp',
        SharePlatform.telegram => 'Telegram',
        SharePlatform.linkedin => 'LinkedIn',
        SharePlatform.pinterest => 'Pinterest',
        SharePlatform.tiktok => 'TikTok',
        SharePlatform.snapchat => 'Snapchat',
        SharePlatform.reddit => 'Reddit',
        SharePlatform.youtube => 'YouTube',
        SharePlatform.wechat => 'WeChat',
        SharePlatform.email => 'Email',
      };

  IconData get icon => switch (this) {
        SharePlatform.facebook => Icons.facebook_rounded,
        SharePlatform.twitter => Icons.close_rounded,
        SharePlatform.instagram => Icons.camera_alt_outlined,
        SharePlatform.whatsapp => Icons.chat_bubble_outline_rounded,
        SharePlatform.telegram => Icons.send_rounded,
        SharePlatform.linkedin => Icons.work_outline_rounded,
        SharePlatform.pinterest => Icons.push_pin_outlined,
        SharePlatform.tiktok => Icons.music_note_rounded,
        SharePlatform.snapchat => Icons.photo_camera_front_outlined,
        SharePlatform.reddit => Icons.forum_outlined,
        SharePlatform.youtube => Icons.play_circle_outline_rounded,
        SharePlatform.wechat => Icons.question_answer_outlined,
        SharePlatform.email => Icons.mail_outline_rounded,
      };

  Color get color => switch (this) {
        SharePlatform.facebook => const Color(0xFF1877F2),
        SharePlatform.twitter => Colors.black,
        SharePlatform.instagram => const Color(0xFFC13584),
        SharePlatform.whatsapp => const Color(0xFF25D366),
        SharePlatform.telegram => const Color(0xFF229ED9),
        SharePlatform.linkedin => const Color(0xFF0A66C2),
        SharePlatform.pinterest => const Color(0xFFE60023),
        SharePlatform.tiktok => Colors.black,
        SharePlatform.snapchat => const Color(0xFFFFD400),
        SharePlatform.reddit => const Color(0xFFFF4500),
        SharePlatform.youtube => const Color(0xFFFF0000),
        SharePlatform.wechat => const Color(0xFF07C160),
        SharePlatform.email => const Color(0xFF5F6368),
      };

  bool get supportsDirectPluginShare => switch (this) {
        SharePlatform.facebook ||
        SharePlatform.twitter ||
        SharePlatform.instagram ||
        SharePlatform.whatsapp ||
        SharePlatform.telegram ||
        SharePlatform.email =>
          true,
        _ => false,
      };

  static SharePlatform? fromId(String id) {
    for (final platform in SharePlatform.values) {
      if (platform.id == id) {
        return platform;
      }
    }
    return null;
  }
}
