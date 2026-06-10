import 'package:image_picker/image_picker.dart';

class ShareContent {
  const ShareContent({
    required this.title,
    required this.text,
    required this.description,
    required this.url,
    required this.hashtags,
    this.image,
  });

  final String title;
  final String text;
  final String description;
  final String url;
  final String hashtags;
  final XFile? image;

  String get formattedMessage {
    final parts = [
      title.trim(),
      text.trim(),
      description.trim(),
      if (url.trim().isNotEmpty) url.trim(),
      if (hashtags.trim().isNotEmpty) _formatHashtags(hashtags),
    ].where((part) => part.isNotEmpty).toList();

    return parts.join('\n\n');
  }

  String _formatHashtags(String value) {
    return value
        .split(RegExp(r'[\s,]+'))
        .where((tag) => tag.trim().isNotEmpty)
        .map((tag) => tag.startsWith('#') ? tag : '#$tag')
        .join(' ');
  }
}

class ShareResult {
  const ShareResult({
    required this.platform,
    required this.success,
    required this.message,
  });

  final String platform;
  final bool success;
  final String message;
}
