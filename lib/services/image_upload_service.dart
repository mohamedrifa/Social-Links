import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

class ImageUploadService {
  static const String apiKey = '3dc87bb28dfe90ea4796500177225b7b';

  static Future<String> uploadImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();

    final response = await Dio().post(
      'https://api.imgbb.com/1/upload',
      data: FormData.fromMap({
        'key': apiKey,
        'image': base64Encode(bytes),
      }),
    );

    if (response.statusCode == 200 &&
        response.data['success'] == true) {
      return response.data['data']['url'];
    }

    throw Exception('Failed to upload image to ImgBB');
  }
}