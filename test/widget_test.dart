import 'package:flutter_test/flutter_test.dart';

import 'package:nko_kalan/main.dart';

void main() {
  testWidgets('App boots to the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const NkoKalanApp());
    await tester.pumpAndSettle();

    expect(find.text("N'Ko Kalan"), findsOneWidget);
  });
}
