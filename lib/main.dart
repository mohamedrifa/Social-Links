import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'sharing/controllers/share_controller.dart';
import 'sharing/screens/social_share_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SocialShareApp());
}

class SocialShareApp extends StatelessWidget {
  const SocialShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShareController(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Social Link',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B63F4),
            surface: const Color(0xFFFAFAFD),
          ),
          scaffoldBackgroundColor: const Color(0xFFFAFAFD),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            backgroundColor: Color(0xFFFAFAFD),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE1E3EA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE1E3EA)),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const SocialShareHomeScreen(),
      ),
    );
  }
}
