import 'package:flutter/material.dart';

import '../models/share_platform.dart';

class PlatformChipGrid extends StatelessWidget {
  const PlatformChipGrid({
    required this.platforms,
    required this.selectedPlatforms,
    required this.onChanged,
    super.key,
  });

  final List<SharePlatform> platforms;
  final Set<SharePlatform> selectedPlatforms;
  final void Function(SharePlatform platform, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    if (platforms.isEmpty) {
      return const _EmptyPlatforms();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 520 ? 4 : 3;

        return GridView.builder(
          itemCount: platforms.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 124,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final platform = platforms[index];
            final selected = selectedPlatforms.contains(platform);

            return _PlatformTile(
              platform: platform,
              selected: selected,
              onTap: () => onChanged(platform, !selected),
            );
          },
        );
      },
    );
  }
}

class _PlatformTile extends StatelessWidget {
  const _PlatformTile({
    required this.platform,
    required this.selected,
    required this.onTap,
  });

  final SharePlatform platform;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? platform.color.withValues(alpha: 0.12)
              : colorScheme.surface,
          border: Border.all(
            color: selected ? platform.color : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: platform.color.withValues(alpha: 0.14),
                child: Icon(platform.icon, color: platform.color, size: 21),
              ),
              const SizedBox(height: 8),
              Text(
                platform.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              const Spacer(),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? platform.color : colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPlatforms extends StatelessWidget {
  const _EmptyPlatforms();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No supported social apps were detected on this device.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
