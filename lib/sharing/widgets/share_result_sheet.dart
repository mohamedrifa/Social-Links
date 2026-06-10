import 'package:flutter/material.dart';

import '../models/share_content.dart';

class ShareResultSheet extends StatelessWidget {
  const ShareResultSheet({required this.results, super.key});

  final List<ShareResult> results;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Share results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            for (final result in results)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  result.success
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: result.success
                      ? Colors.green.shade700
                      : Theme.of(context).colorScheme.error,
                ),
                title: Text(result.platform),
                subtitle: Text(result.message),
              ),
          ],
        ),
      ),
    );
  }
}
