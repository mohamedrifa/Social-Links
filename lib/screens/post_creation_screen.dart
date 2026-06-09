import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/post_provider.dart';
import '../services/social_share_service.dart';
import '../utils/validators.dart';
import '../widgets/image_picker_card.dart';
import '../widgets/platform_checkbox_tile.dart';

class PostCreationScreen extends ConsumerStatefulWidget {
  const PostCreationScreen({super.key});

  @override
  ConsumerState<PostCreationScreen> createState() =>
      _PostCreationScreenState();
}

class _PostCreationScreenState
    extends ConsumerState<PostCreationScreen> {

  final formKey = GlobalKey<FormState>();

  final descriptionController =
      TextEditingController();

  File? image;

  Future<void> pickImage() async {
    final result = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (result != null) {
      setState(() {
        image = File(result.path);
      });
    }
  }

  // Future<void> submit() async {
  //   if (image == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Please select image'),
  //       ),
  //     );
  //     return;
  //   }

  //   if (!formKey.currentState!.validate()) {
  //     return;
  //   }

  //   final platforms = ref.read(postProvider);

  //   final selectedPlatforms = platforms
  //       .where((e) => e.selected)
  //       .map((e) => e.id)
  //       .toList();

  //   if (selectedPlatforms.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Select at least one platform'),
  //       ),
  //     );
  //     return;
  //   }

  //   try {
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (_) => const Center(
  //         child: CircularProgressIndicator(),
  //       ),
  //     );

  //     // Upload image and get public URL
  //     final imageUrl = await ImageUploadService.uploadImage(image!);

  //     final post = PostModel(
  //       image: image!,
  //       description: descriptionController.text.trim(),
  //       platforms: selectedPlatforms,
  //     );

  //     final publisher = PublishManager(
  //       facebookService: FacebookService(
  //         dio: Dio(),
  //         pageId: facebookPageId,
  //         accessToken: facebookAccessToken,
  //       ),
  //       instagramService: InstagramService(
  //         dio: Dio(),
  //         instagramBusinessId: instagramBusinessId,
  //         accessToken: instagramAccessToken,
  //       ),
  //       telegramService: TelegramService(
  //         dio: Dio(),
  //         botToken: telegramBotToken,
  //         chatId: telegramChatId,
  //       ),
  //     );

  //     await publisher.publishPost(
  //       post: post,
  //       imageUrl: imageUrl,
  //     );

  //     if (mounted) {
  //       if (Navigator.canPop(context)) {
  //         Navigator.pop(context);
  //       }

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text(
  //             'Post published successfully',
  //           ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       if (Navigator.canPop(context)) {
  //         Navigator.pop(context);
  //       }

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(
  //             'Failed to publish: $e',
  //           ),
  //         ),
  //       );
  //     }
  //   }
  // }

  Future<void> submit() async {
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select image'),
        ),
      );
      return;
    }

    if (!formKey.currentState!.validate()) {
      return;
    }

    final selectedPlatforms = ref
        .read(postProvider)
        .where((e) => e.selected)
        .map((e) => e.id)
        .toList();

    if (selectedPlatforms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one platform'),
        ),
      );
      return;
    }

    final caption = descriptionController.text.trim();

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                'Ready to Publish',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              ...selectedPlatforms.map(
                (platform) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {

                      Navigator.pop(context);

                      switch (platform) {
                        case 'instagram':
                          await SocialShareService
                              .openInstagram(
                            image!,
                            caption,
                          );
                          break;

                        case 'facebook':
                          await SocialShareService
                              .openFacebook(
                            image!,
                            caption,
                          );
                          break;

                        case 'telegram':
                          await SocialShareService
                              .openTelegram(
                            caption,
                          );
                          break;

                        case 'whatsapp':
                          await SocialShareService
                              .openWhatsApp(
                            caption,
                          );
                          break;

                        case 'twitter':
                          await SocialShareService
                              .openTwitter(
                            caption,
                          );
                          break;
                      }
                    },
                    child: Text(
                      'Open ${platform.toUpperCase()}',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final platforms =
        ref.watch(postProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Post",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            children: [

              ImagePickerCard(
                image: image,
                onTap: pickImage,
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller:
                    descriptionController,
                maxLines: 5,
                validator:
                    Validators.description,
                decoration:
                    const InputDecoration(
                  labelText:
                      "Description",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  "Share To",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
              ),

              const SizedBox(height: 12),

              ...platforms
                  .where((e) =>
                      e.hasCredential)
                  .map(
                    (platform) =>
                        PlatformCheckboxTile(
                      title:
                          platform.name,
                      value:
                          platform.selected,
                      onChanged: (_) {
                        ref
                            .read(
                              postProvider
                                  .notifier,
                            )
                            .togglePlatform(
                              platform.id,
                            );
                      },
                    ),
                  ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  onPressed: submit,
                  child: const Text(
                    "Publish Post",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}