// Smoke test: the app builds and routes to the login screen when logged out.
import 'package:archiquant_flutter/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots to the login screen when logged out', (WidgetTester tester) async {
    await tester.pumpWidget(ArchiQuantApp());
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
