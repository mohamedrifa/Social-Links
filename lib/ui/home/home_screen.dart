import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _postController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Image picker error: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool?> _showConfirmationDialog(String title, String content, String yesText, String noText) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(noText),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(yesText),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLoginLogout(String platform) async {
    final authState = ref.read(authControllerProvider);
    final authController = ref.read(authControllerProvider.notifier);

    if (platform == 'FACEBOOK') {
      if (authState.fbLoginState) {
        final result = await _showConfirmationDialog('Status', 'Do you want logout ?', 'Yes', 'No');
        if (result == true) {
          await authController.toggleFacebookLogin();
        }
      } else {
        await authController.toggleFacebookLogin();
      }
    } else if (platform == 'TWITTER') {
      if (authState.twitterLoginState) {
        final result = await _showConfirmationDialog('Status', 'Do you want logout ?', 'Yes', 'No');
        if (result == true) {
          await authController.toggleTwitterLogin();
        }
      } else {
        await authController.toggleTwitterLogin();
      }
    }
    
    // Check for errors after attempting login/logout
    final newState = ref.read(authControllerProvider);
    if (newState.errorMessage != null) {
      _showError(newState.errorMessage!);
    }
  }

  Future<void> _handlePost() async {
    final authState = ref.read(authControllerProvider);
    if (_postController.text.isEmpty) {
      _showConfirmationDialog('Alert', 'Kindly Fill the text to share', 'OK', 'Cancel');
      return;
    }

    if (authState.fbLoginState && authState.twitterLoginState) {
      await _executePost(3, 'Logged in on FB / Twitter. Want to share on both ?');
    } else if (authState.fbLoginState && !authState.twitterLoginState) {
      await _executePost(1, 'Logged in FB only. Want to share FB alone ?');
    } else if (!authState.fbLoginState && authState.twitterLoginState) {
      await _executePost(2, 'Logged in Twitter only. Want to share Twitter alone ?');
    } else {
      _showConfirmationDialog('Alert', 'Kindly Login FB/Twitter to post your Message', 'OK', 'Cancel');
    }
  }

  Future<void> _executePost(int id, String message) async {
    final result = await _showConfirmationDialog('Alert', message, 'Yes', 'No');
    if (result == true) {
      final authController = ref.read(authControllerProvider.notifier);
      final success = await authController.postMessage(id, _postController.text);
      if (success) {
        _postController.clear();
        await _showConfirmationDialog('Alert', 'Given text shared.', 'OK', 'Cancel');
      } else {
        final error = ref.read(authControllerProvider).errorMessage ?? 'Failed to post message.';
        _showConfirmationDialog('Alert', error, 'OK', 'Cancel');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social App'),
      ),
      body: authState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImage == null
                          ? const Center(
                              child: Text('Tap to Pick an Image'),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _postController,
                    decoration: const InputDecoration(
                      labelText: 'What\'s on your mind?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _handleLoginLogout('FACEBOOK'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                    child: Text(
                      authState.fbLoginState ? 'Facebook Logout' : 'Facebook Login',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _handleLoginLogout('TWITTER'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
                    child: Text(
                      authState.twitterLoginState ? 'Twitter Logout' : 'Twitter Login',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _handlePost,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('POST', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
    );
  }
}
