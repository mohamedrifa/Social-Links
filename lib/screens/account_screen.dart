import 'package:flutter/material.dart';

import '../models/social_account.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({
    required this.accounts,
    required this.onConnect,
    required this.onSignOut,
    this.loadingPlatform,
    super.key,
  });

  final Map<SocialPlatform, SocialAccount?> accounts;
  final Future<void> Function(SocialPlatform platform) onConnect;
  final Future<void> Function(SocialPlatform platform) onSignOut;
  final SocialPlatform? loadingPlatform;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Accounts',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Connect the platforms you want to publish to.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          for (final platform in SocialPlatform.values) ...[
            _AccountTile(
              platform: platform,
              account: accounts[platform],
              isLoading: loadingPlatform == platform,
              onConnect: () => onConnect(platform),
              onSignOut: () => onSignOut(platform),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.platform,
    required this.account,
    required this.isLoading,
    required this.onConnect,
    required this.onSignOut,
  });

  final SocialPlatform platform;
  final SocialAccount? account;
  final bool isLoading;
  final Future<void> Function() onConnect;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final connected = account != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: connected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          backgroundImage:
              account?.avatarUrl != null ? NetworkImage(account!.avatarUrl!) : null,
          child: account?.avatarUrl == null
              ? Icon(
                  switch (platform) {
                    SocialPlatform.facebook => Icons.facebook_rounded,
                    SocialPlatform.instagram => Icons.camera_alt_outlined,
                    SocialPlatform.twitter => Icons.close_rounded,
                  },
                )
              : null,
        ),
        title: Text(
          account?.displayName ?? platform.displayName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          connected
              ? [
                  if (account!.username != null) '@${account!.username}',
                  if (account!.email != null) account!.email!,
                  'Connected ${_formatDate(account!.connectedAt)}',
                ].join(' | ')
              : _disconnectedMessage(platform),
        ),
        trailing: connected
            ? TextButton(
                onPressed: isLoading ? null : onSignOut,
                child: const Text('Sign out'),
              )
            : FilledButton(
                onPressed: isLoading ? null : onConnect,
                child: isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_connectLabel(platform)),
              ),
      ),
    );
  }

  String _connectLabel(SocialPlatform platform) {
    return switch (platform) {
      SocialPlatform.instagram => 'Connect',
      SocialPlatform.facebook => 'Connect',
      SocialPlatform.twitter => 'Connect',
    };
  }

  String _disconnectedMessage(SocialPlatform platform) {
    return switch (platform) {
      SocialPlatform.instagram =>
        'Uses your connected Facebook Page and Instagram professional account',
      SocialPlatform.facebook => 'Not connected',
      SocialPlatform.twitter => 'Not connected',
    };
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
