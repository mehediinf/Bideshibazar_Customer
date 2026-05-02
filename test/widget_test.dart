import 'package:flutter_test/flutter_test.dart';

import 'package:bideshibazar/main.dart';

void main() {
  testWidgets('MyApp renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Minimal smoke assertion for current app shell.
    expect(find.byType(MyApp), findsOneWidget);
  });
}
