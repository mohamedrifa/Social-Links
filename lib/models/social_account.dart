import 'dart:convert';

enum SocialPlatform {
  twitter,
  facebook,
  instagram,
}

extension SocialPlatformLabel on SocialPlatform {
  String get storageKey => switch (this) {
        SocialPlatform.twitter => 'twitter',
        SocialPlatform.facebook => 'facebook',
        SocialPlatform.instagram => 'instagram',
      };

  String get displayName => switch (this) {
        SocialPlatform.twitter => 'X',
        SocialPlatform.facebook => 'Facebook',
        SocialPlatform.instagram => 'Instagram',
      };
}

class SocialAccount {
  const SocialAccount({
    required this.platform,
    required this.id,
    required this.displayName,
    required this.connectedAt,
    this.username,
    this.email,
    this.avatarUrl,
  });

  final SocialPlatform platform;
  final String id;
  final String displayName;
  final String? username;
  final String? email;
  final String? avatarUrl;
  final DateTime connectedAt;

  Map<String, dynamic> toMap() {
    return {
      'platform': platform.storageKey,
      'id': id,
      'displayName': displayName,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'connectedAt': connectedAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  factory SocialAccount.fromMap(Map<String, dynamic> map) {
    final platformValue = map['platform'] as String? ?? 'twitter';

    return SocialAccount(
      platform: SocialPlatform.values.firstWhere(
        (platform) => platform.storageKey == platformValue,
        orElse: () => SocialPlatform.twitter,
      ),
      id: map['id'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Connected account',
      username: map['username'] as String?,
      email: map['email'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      connectedAt: DateTime.tryParse(map['connectedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory SocialAccount.fromJson(String source) {
    return SocialAccount.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}
