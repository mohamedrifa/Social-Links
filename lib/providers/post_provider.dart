import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';

import '../models/social_platform_model.dart';

class PostNotifier extends StateNotifier<List<SocialPlatformModel>> {
  PostNotifier() : super([
          SocialPlatformModel(
            id: "facebook",
            name: "Facebook",
            hasCredential: true,
          ),
          SocialPlatformModel(
            id: "instagram",
            name: "Instagram",
            hasCredential: true,
          ),
          SocialPlatformModel(
            id: "telegram",
            name: "Telegram",
            hasCredential: true,
          ),
        ]);

  File? image;
  String description = "";

  void togglePlatform(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
          SocialPlatformModel(
            id: item.id,
            name: item.name,
            hasCredential: item.hasCredential,
            selected: !item.selected,
          )
        else
          item,
    ];
  }
}

final postProvider =
    StateNotifierProvider<PostNotifier, List<SocialPlatformModel>>(
  (ref) => PostNotifier(),
);