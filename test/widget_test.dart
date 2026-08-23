import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nko_kalan/screens/auth_screen.dart';
import 'package:nko_kalan/theme/app_theme.dart';

void main() {
  // NkoKalanApp's AuthGate reads FirebaseAuth.instance, which needs a real
  // platform binding that isn't available in the widget-test environment.
  // AuthScreen is the concrete widget it renders for a signed-out user (see
  // main.dart), so we pump that directly to keep this a genuine smoke test
  // without brittle Firebase platform-channel mocking.
  testWidgets('Sign-in screen shows the app title', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: const AuthScreen()));
    await tester.pumpAndSettle();

    expect(find.text("N'Ko Kalan"), findsOneWidget);
  });
}
