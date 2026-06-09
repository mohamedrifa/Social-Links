import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/social_account.dart';
import '../models/social_post_payload.dart';
import '../services/social_posting_service.dart';

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({
    required this.accounts,
    required this.postingService,
    super.key,
  });

  final Map<SocialPlatform, SocialAccount?> accounts;
  final SocialPostingService postingService;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();
  final Set<SocialPlatform> _selectedPlatforms = {};
  final Map<SocialPlatform, PlatformPostResult> _lastResults = {};
  XFile? _selectedImage;
  bool _isPosting = false;
  bool _hasSyncedInitialPlatforms = false;

  static const _publicImageUrl = String.fromEnvironment(
    'PUBLIC_IMAGE_URL_FOR_META_POSTING',
  );

  @override
  void initState() {
    super.initState();
    _syncSelectedPlatforms();
  }

  @override
  void didUpdateWidget(covariant ComposeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelectedPlatforms();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final connectedAccounts = Map<SocialPlatform, SocialAccount?>.fromEntries(
      widget.accounts.entries.where((entry) => entry.value != null),
    );
    final primaryAccount =
        connectedAccounts.isEmpty ? null : connectedAccounts.values.first;
    final hasConnectedAccount = connectedAccounts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Compose')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: primaryAccount?.avatarUrl != null
                            ? NetworkImage(primaryAccount!.avatarUrl!)
                            : null,
                        child: primaryAccount?.avatarUrl == null
                            ? const Icon(Icons.person_outline)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              primaryAccount?.displayName ??
                                  'No accounts connected',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              hasConnectedAccount
                                  ? '${connectedAccounts.length} account${connectedAccounts.length == 1 ? '' : 's'} ready'
                                  : 'Connect an account before publishing.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _textController,
                    enabled: hasConnectedAccount && !_isPosting,
                    maxLines: 5,
                    maxLength: 280,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      labelText: 'What would you like to post?',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PlatformSelector(
                    accounts: connectedAccounts,
                    selectedPlatforms: _selectedPlatforms,
                    results: _lastResults,
                    isPosting: _isPosting,
                    onChanged: (platform, selected) {
                      setState(() {
                        if (selected) {
                          _selectedPlatforms.add(platform);
                        } else {
                          _selectedPlatforms.remove(platform);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _ImagePreview(
                    image: _selectedImage,
                    onPickImage: hasConnectedAccount ? _pickImage : null,
                    onRemoveImage: _selectedImage == null
                        ? null
                        : () => setState(() => _selectedImage = null),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: hasConnectedAccount &&
                              _selectedPlatforms.isNotEmpty &&
                              !_isPosting
                          ? _post
                          : null,
                      icon: _isPosting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: const Text('Post'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      setState(() => _selectedImage = image);
    }
  }

  void _syncSelectedPlatforms() {
    final connectedPlatforms = widget.accounts.entries
        .where((entry) => entry.value != null)
        .map((entry) => entry.key)
        .toSet();

    if (!_hasSyncedInitialPlatforms) {
      _selectedPlatforms.addAll(connectedPlatforms);
      _hasSyncedInitialPlatforms = true;
      return;
    }

    _selectedPlatforms.removeWhere(
      (platform) => !connectedPlatforms.contains(platform),
    );
  }

  Future<void> _post() async {
    setState(() {
      _isPosting = true;
      _lastResults.clear();
    });

    try {
      final results = await widget.postingService.postToPlatforms(
        payload: SocialPostPayload(
          text: _textController.text,
          image: _selectedImage,
          publicImageUrl: _publicImageUrl.isEmpty ? null : _publicImageUrl,
        ),
        platforms: _selectedPlatforms,
      );
      if (!mounted) {
        return;
      }

      final allSuccessful = results.every((result) => result.success);
      setState(() {
        for (final result in results) {
          _lastResults[result.platform] = result;
        }
        if (allSuccessful) {
          _textController.clear();
          _selectedImage = null;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_buildResultMessage(results))),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  String _buildResultMessage(List<PlatformPostResult> results) {
    final successful = results.where((result) => result.success).toList();
    final failed = results.where((result) => !result.success).toList();

    if (failed.isEmpty) {
      return 'Posted to ${successful.map((r) => r.platform.displayName).join(', ')}.';
    }

    if (successful.isEmpty) {
      return 'Posting failed: ${failed.map((r) => '${r.platform.displayName}: ${r.message}').join(' | ')}';
    }

    return 'Posted to ${successful.map((r) => r.platform.displayName).join(', ')}. Failed: ${failed.map((r) => r.platform.displayName).join(', ')}.';
  }
}

class _PlatformSelector extends StatelessWidget {
  const _PlatformSelector({
    required this.accounts,
    required this.selectedPlatforms,
    required this.results,
    required this.isPosting,
    required this.onChanged,
  });

  final Map<SocialPlatform, SocialAccount?> accounts;
  final Set<SocialPlatform> selectedPlatforms;
  final Map<SocialPlatform, PlatformPostResult> results;
  final bool isPosting;
  final void Function(SocialPlatform platform, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (final entry in accounts.entries)
            CheckboxListTile(
              value: selectedPlatforms.contains(entry.key),
              onChanged: isPosting
                  ? null
                  : (selected) => onChanged(entry.key, selected ?? false),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              title: Text(entry.key.displayName),
              subtitle: _PlatformStatus(result: results[entry.key]),
              secondary: Icon(_platformIcon(entry.key)),
            ),
        ],
      ),
    );
  }

  IconData _platformIcon(SocialPlatform platform) {
    return switch (platform) {
      SocialPlatform.twitter => Icons.close_rounded,
      SocialPlatform.facebook => Icons.facebook_rounded,
      SocialPlatform.instagram => Icons.camera_alt_outlined,
    };
  }
}

class _PlatformStatus extends StatelessWidget {
  const _PlatformStatus({required this.result});

  final PlatformPostResult? result;

  @override
  Widget build(BuildContext context) {
    final result = this.result;
    if (result == null) {
      return const Text('Ready');
    }

    return Text(
      result.success ? 'Posted' : result.message,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: result.success
            ? Colors.green.shade700
            : Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.image,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final XFile? image;
  final VoidCallback? onPickImage;
  final VoidCallback? onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (image == null) {
      return OutlinedButton.icon(
        onPressed: onPickImage,
        icon: const Icon(Icons.photo_library_outlined),
        label: const Text('Add image from gallery'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.file(
              File(image!.path),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                image!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            IconButton(
              tooltip: 'Remove image',
              onPressed: onRemoveImage,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ],
    );
  }
}
