import 'package:flutter/material.dart';

import 'models/social_account.dart';
import 'screens/account_screen.dart';
import 'screens/compose_screen.dart';
import 'services/facebook_service.dart';
import 'services/instagram_service.dart';
import 'services/oauth_service.dart';
import 'services/social_posting_service.dart';
import 'services/twitter_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Social Link',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF246BFD),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const SocialLinkApp(),
    );
  }
}

class SocialLinkApp extends StatefulWidget {
  const SocialLinkApp({super.key});

  @override
  State<SocialLinkApp> createState() => _SocialLinkAppState();
}

class _SocialLinkAppState extends State<SocialLinkApp> {
  late final OAuthService _oauthService;
  late final TwitterService _twitterService;
  late final FacebookService _facebookService;
  late final InstagramService _instagramService;
  late final SocialPostingService _postingService;
  final Map<SocialPlatform, SocialAccount?> _accounts = {
    SocialPlatform.twitter: null,
    SocialPlatform.facebook: null,
    SocialPlatform.instagram: null,
  };

  bool _isRestoring = true;
  SocialPlatform? _loadingPlatform;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _oauthService = OAuthService();
    _twitterService = TwitterService(oauthService: _oauthService);
    _facebookService = FacebookService(oauthService: _oauthService);
    _instagramService = InstagramService(
      oauthService: _oauthService,
      pageAccessTokenProvider: _facebookService.getPageAccessToken,
    );
    _postingService = SocialPostingService(
      twitterService: _twitterService,
      facebookService: _facebookService,
      instagramService: _instagramService,
    );
    _restoreAccounts();
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      ComposeScreen(
        accounts: _accounts,
        postingService: _postingService,
      ),
      AccountScreen(
        accounts: _accounts,
        loadingPlatform: _loadingPlatform,
        onConnect: _connectPlatform,
        onSignOut: _signOut,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: 'Compose',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Accounts',
          ),
        ],
      ),
    );
  }

  Future<void> _restoreAccounts() async {
    final twitterAccount = await _twitterService.restoreAccount();
    final facebookAccount = await _facebookService.restoreAccount();
    final instagramAccount = await _instagramService.restoreAccount();

    if (!mounted) {
      return;
    }

    setState(() {
      _accounts[SocialPlatform.twitter] = twitterAccount;
      _accounts[SocialPlatform.facebook] = facebookAccount;
      _accounts[SocialPlatform.instagram] = instagramAccount;
      if (_accounts.values.every((account) => account == null)) {
        _selectedIndex = 1;
      }
      _isRestoring = false;
    });
  }

  Future<SocialAccount?> _connectTwitter() async {
    final account = await _twitterService.signIn();
    if (account != null && mounted) {
      setState(() => _accounts[SocialPlatform.twitter] = account);
    }

    return account;
  }

  Future<SocialAccount?> _connectFacebook() async {
    final account = await _facebookService.signIn();
    if (account != null && mounted) {
      setState(() => _accounts[SocialPlatform.facebook] = account);
    }

    return account;
  }

  Future<void> _connectPlatform(SocialPlatform platform) async {
    if (_loadingPlatform != null) {
      return;
    }

    setState(() => _loadingPlatform = platform);

    try {
      SocialAccount? account;
      if (platform == SocialPlatform.twitter) {
        account = await _connectTwitter();
      } else if (platform == SocialPlatform.facebook) {
        account = await _connectFacebook();
      } else {
        account = await _connectInstagram();
      }

      if (!mounted || account == null) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${platform.displayName} connected.')),
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

  Future<SocialAccount?> _connectInstagram() async {
    if (_accounts[SocialPlatform.facebook] == null) {
      await _connectFacebook();
    }

    await _facebookService.requestPublishingPermissions();
    await _instagramService.connectFromFacebookAccount();
    final instagramAccount = await _instagramService.restoreAccount();

    if (instagramAccount != null && mounted) {
      setState(() => _accounts[SocialPlatform.instagram] = instagramAccount);
    }

    if (instagramAccount == null) {
      throw Exception(
        'Instagram needs a Facebook Page connected to an Instagram professional account. Add FACEBOOK_PAGE_ID when running the app, or provide INSTAGRAM_BUSINESS_ACCOUNT_ID.',
      );
    }

    return instagramAccount;
  }

  Future<void> _signOut(SocialPlatform platform) async {
    if (platform == SocialPlatform.twitter) {
      await _twitterService.signOut();
    } else if (platform == SocialPlatform.facebook) {
      await _facebookService.signOut();
      await _instagramService.signOut();
    } else {
      await _instagramService.signOut();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _accounts[platform] = null;
      if (platform == SocialPlatform.facebook) {
        _accounts[SocialPlatform.instagram] = null;
      }
      if (_accounts.values.every((account) => account == null)) {
        _selectedIndex = 1;
      }
    });
  }
}
