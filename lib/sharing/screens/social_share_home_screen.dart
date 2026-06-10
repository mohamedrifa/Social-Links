import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/share_controller.dart';
import '../models/share_content.dart';
import '../widgets/platform_chip_grid.dart';
import '../widgets/share_result_sheet.dart';

class SocialShareHomeScreen extends StatefulWidget {
  const SocialShareHomeScreen({super.key});

  @override
  State<SocialShareHomeScreen> createState() => _SocialShareHomeScreenState();
}

class _SocialShareHomeScreenState extends State<SocialShareHomeScreen> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  final _hashtagsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShareController>().loadInstalledApps();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShareController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Social Share'),
            actions: [
              IconButton(
                tooltip: 'Refresh installed apps',
                onPressed: controller.isLoadingApps
                    ? null
                    : controller.loadInstalledApps,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _Header(
                availableCount: controller.availablePlatforms.length,
                isLoading: controller.isLoadingApps,
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Post content',
                icon: Icons.edit_note_rounded,
                child: _ComposerFields(
                  titleController: _titleController,
                  textController: _textController,
                  descriptionController: _descriptionController,
                  urlController: _urlController,
                  hashtagsController: _hashtagsController,
                ),
              ),
              const SizedBox(height: 14),
              _Section(
                title: 'Media',
                icon: Icons.image_outlined,
                child: _ImagePickerPanel(controller: controller),
              ),
              const SizedBox(height: 14),
              _Section(
                title: 'Share to',
                icon: Icons.apps_rounded,
                trailing: TextButton.icon(
                  onPressed: controller.isLoadingApps
                      ? null
                      : controller.loadInstalledApps,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                ),
                child: PlatformChipGrid(
                  platforms: controller.availablePlatforms,
                  selectedPlatforms: controller.selectedPlatforms,
                  onChanged: controller.togglePlatform,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: controller.isSharing ? null : _share,
                icon: controller.isSharing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: Text(
                  controller.selectedPlatforms.isEmpty
                      ? 'Select an app'
                      : 'Share to ${controller.selectedPlatforms.length} app${controller.selectedPlatforms.length == 1 ? '' : 's'}',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _share() async {
    final controller = context.read<ShareController>();
    final content = ShareContent(
      title: _titleController.text,
      text: _textController.text,
      description: _descriptionController.text,
      url: _urlController.text,
      hashtags: _hashtagsController.text,
      image: controller.image,
    );

    final results = await controller.share(content);
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      builder: (_) => ShareResultSheet(results: results),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.availableCount,
    required this.isLoading,
  });

  final int availableCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.hub_outlined, color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create once, share anywhere',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoading
                        ? 'Checking installed apps...'
                        : '$availableCount sharing option${availableCount == 1 ? '' : 's'} detected',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E8EE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ComposerFields extends StatelessWidget {
  const _ComposerFields({
    required this.titleController,
    required this.textController,
    required this.descriptionController,
    required this.urlController,
    required this.hashtagsController,
  });

  final TextEditingController titleController;
  final TextEditingController textController;
  final TextEditingController descriptionController;
  final TextEditingController urlController;
  final TextEditingController hashtagsController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: textController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Message',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descriptionController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Description',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: urlController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'URL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: hashtagsController,
          decoration: const InputDecoration(
            labelText: 'Hashtags',
            hintText: 'flutter, social, launch',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _ImagePickerPanel extends StatelessWidget {
  const _ImagePickerPanel({required this.controller});

  final ShareController controller;

  @override
  Widget build(BuildContext context) {
    final image = controller.image;

    if (image == null) {
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: controller.pickImage,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FC),
            border: Border.all(color: const Color(0xFFE1E3EA)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 18, horizontal: 14),
            child: Row(
              children: [
                Icon(Icons.photo_library_outlined),
                SizedBox(width: 10),
                Expanded(child: Text('Attach image from gallery')),
                Icon(Icons.add_rounded),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.file(File(image.path), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                image.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Remove image',
              onPressed: controller.removeImage,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
