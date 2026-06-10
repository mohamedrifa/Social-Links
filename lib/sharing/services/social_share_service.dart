import 'package:flutter_social_share_plugin/file_type.dart';
import 'package:flutter_social_share_plugin/flutter_social_share.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/share_content.dart';
import '../models/share_platform.dart';

class SocialShareService {
  SocialShareService({FlutterSocialShare? plugin})
      : _plugin = plugin ?? FlutterSocialShare();

  final FlutterSocialShare _plugin;

  Future<ShareResult> share({
    required SharePlatform platform,
    required ShareContent content,
  }) async {
    try {
      final message = content.formattedMessage;
      final imagePath = content.image?.path;
      String? response;

      switch (platform) {
        case SharePlatform.facebook:
          response = await _plugin.shareToFacebook(
            msg: message,
            imagePath: imagePath ?? '',
          );
        case SharePlatform.twitter:
          response = await _plugin.shareToTwitter(
            msg: message,
            url: content.url.trim(),
          );
        case SharePlatform.instagram:
          if (imagePath == null) {
            throw const ShareException('Instagram sharing requires an image.');
          }
          response = await _plugin.shareToInstagram(
            filePath: imagePath,
            fileType: FileType.image,
          );
        case SharePlatform.whatsapp:
          if (imagePath == null) {
            response = await _plugin.shareToWhatsApp(msg: message);
          } else {
            response = await _plugin.shareToWhatsApp(
              msg: message,
              imagePath: imagePath,
              fileType: FileType.image,
            );
          }
        case SharePlatform.telegram:
          response = await _plugin.shareToTelegram(msg: message);
        case SharePlatform.email:
          response = await _plugin.shareToMail(
            mailSubject: content.title.trim().isEmpty
                ? 'Shared from Social Link'
                : content.title.trim(),
            mailBody: message,
            mailRecipients: const <String>[],
          );
        case SharePlatform.linkedin:
          response = await _openUrl(
            Uri.https('www.linkedin.com', '/sharing/share-offsite/', {
              if (content.url.trim().isNotEmpty) 'url': content.url.trim(),
            }),
          );
        case SharePlatform.pinterest:
          response = await _openUrl(
            Uri.https('www.pinterest.com', '/pin/create/button/', {
              if (content.url.trim().isNotEmpty) 'url': content.url.trim(),
              'description': message,
              if (imagePath != null) 'media': imagePath,
            }),
          );
        case SharePlatform.tiktok:
          response = await _openUrl(Uri.parse('tiktok://'));
        case SharePlatform.snapchat:
          response = await _openUrl(Uri.parse('snapchat://'));
        case SharePlatform.reddit:
          response = await _openUrl(
            Uri.https('www.reddit.com', '/submit', {
              if (content.url.trim().isNotEmpty) 'url': content.url.trim(),
              'title': content.title.trim().isEmpty
                  ? content.text.trim()
                  : content.title.trim(),
            }),
          );
        case SharePlatform.youtube:
          response = await _openUrl(Uri.parse('youtube://'));
        case SharePlatform.wechat:
          response = await _openUrl(Uri.parse('wechat://'));
      }

      return ShareResult(
        platform: platform.label,
        success: true,
        message: response ?? 'Opened ${platform.label}.',
      );
    } catch (error) {
      return ShareResult(
        platform: platform.label,
        success: false,
        message: error.toString(),
      );
    }
  }

  Future<List<ShareResult>> shareToMany({
    required Iterable<SharePlatform> platforms,
    required ShareContent content,
  }) async {
    final results = <ShareResult>[];
    for (final platform in platforms) {
      results.add(await share(platform: platform, content: content));
    }
    return results;
  }

  Future<String> _openUrl(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw ShareException('Could not open $uri.');
    }
    return 'success';
  }
}

class ShareException implements Exception {
  const ShareException(this.message);

  final String message;

  @override
  String toString() => message;
}
