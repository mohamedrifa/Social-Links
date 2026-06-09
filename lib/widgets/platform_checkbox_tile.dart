import 'package:flutter/material.dart';

class PlatformCheckboxTile extends StatelessWidget {
  final String title;
  final bool value;
  final Function(bool?) onChanged;

  const PlatformCheckboxTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}