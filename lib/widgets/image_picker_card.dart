import 'dart:io';

import 'package:flutter/material.dart';

class ImagePickerCard extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;

  const ImagePickerCard({
    super.key,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  image!,
                  fit: BoxFit.cover,
                ),
              )
            : const Center(
                child: Icon(Icons.add_a_photo),
              ),
      ),
    );
  }
}