import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:social_link/screens/login_screen.dart';

void main() {
  testWidgets('shows social login actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onTwitterLogin: () async => null,
          onFacebookLogin: () async => null,
        ),
      ),
    );

    expect(find.text('Continue with X'), findsOneWidget);
    expect(find.text('Continue with Facebook'), findsOneWidget);
  });
}
