import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialShareService {
  static Future<void> openInstagram(
    File image,
    String caption,
  ) async {
    await Share.shareXFiles(
      [XFile(image.path)],
      text: caption,
      subject: 'Instagram Post',
    );
  }

  static Future<void> openFacebook(
    File image,
    String caption,
  ) async {
    await Share.shareXFiles(
      [XFile(image.path)],
      text: caption,
      subject: 'Facebook Post',
    );
  }

  static Future<void> openTelegram(
    String message,
  ) async {
    final uri = Uri.parse(
      'https://t.me/share/url?url=&text=${Uri.encodeComponent(message)}',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<void> openWhatsApp(
    String message,
  ) async {
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<void> openTwitter(
    String message,
  ) async {
    final uri = Uri.parse(
      'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(message)}',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<void> openLinkedIn(
    String message,
  ) async {
    final uri = Uri.parse(
      'https://www.linkedin.com/feed/',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
}