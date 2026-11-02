import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/main.dart';

void main() {
  testWidgets('shows the SOS Companion home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SosCompanionApp()));
    await tester.pump();

    expect(find.text('SOS Companion'), findsOneWidget);
    expect(find.text('Mulai Monitoring'), findsOneWidget);
    expect(find.text('Kontak Darurat'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
  });
}
