class SocialPlatformModel {
  final String id;
  final String name;
  final bool hasCredential;
  bool selected;

  SocialPlatformModel({
    required this.id,
    required this.name,
    required this.hasCredential,
    this.selected = false,
  });
}