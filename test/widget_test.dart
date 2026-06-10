import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:social_link/sharing/controllers/share_controller.dart';
import 'package:social_link/sharing/screens/social_share_home_screen.dart';

void main() {
  testWidgets('shows social share composer', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ShareController(),
        child: const MaterialApp(home: SocialShareHomeScreen()),
      ),
    );

    expect(find.text('Compose'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
  });
}
