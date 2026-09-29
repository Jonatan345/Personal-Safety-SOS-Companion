// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:sos_companion/main.dart';

void main() {
  testWidgets('shows the SOS Companion home screen',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SosCompanionApp());

    // Verify that our counter starts at 0.
    expect(find.text('SOS Companion'), findsOneWidget);
    expect(find.text('Mulai Monitoring'), findsOneWidget);

    // Tap the '+' icon and trigger a frame.
    await tester.pump();
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
  });
}
