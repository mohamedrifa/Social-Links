import 'dart:io';

class PostModel {
  final File image;
  final String description;
  final List<String> platforms;

  PostModel({
    required this.image,
    required this.description,
    required this.platforms,
  });
}