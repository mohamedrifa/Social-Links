import 'package:flutter/material.dart';

import '../models/social_account.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.onTwitterLogin,
    required this.onFacebookLogin,
    super.key,
  });

  final Future<SocialAccount?> Function() onTwitterLogin;
  final Future<SocialAccount?> Function() onFacebookLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  SocialPlatform? _loadingPlatform;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.hub_outlined,
                    size: 56,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Social Link',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect your accounts and compose posts from one workspace.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 36),
                  _LoginButton(
                    label: 'Continue with X',
                    icon: Icons.close_rounded,
                    isLoading: _loadingPlatform == SocialPlatform.twitter,
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    onPressed: () => _handleLogin(
                      SocialPlatform.twitter,
                      widget.onTwitterLogin,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LoginButton(
                    label: 'Continue with Facebook',
                    icon: Icons.facebook_rounded,
                    isLoading: _loadingPlatform == SocialPlatform.facebook,
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF1877F2),
                    onPressed: () => _handleLogin(
                      SocialPlatform.facebook,
                      widget.onFacebookLogin,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(
    SocialPlatform platform,
    Future<SocialAccount?> Function() login,
  ) async {
    if (_loadingPlatform != null) {
      return;
    }

    setState(() => _loadingPlatform = platform);

    try {
      final account = await login();
      if (!mounted || account == null) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${account.platform.displayName} connected.')),
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
        setState(() => _loadingPlatform = null);
      }
    }
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foregroundColor,
              ),
            )
          : Icon(icon),
      label: Text(label),
    );
  }
}
