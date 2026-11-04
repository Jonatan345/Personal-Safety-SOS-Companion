import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/main.dart';
import 'package:sos_companion/repositories/emergency_contact_repository.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('shows the SOS Companion home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emergencyContactRepositoryProvider
              .overrideWithValue(FakeEmergencyContactRepository()),
        ],
        child: const SosCompanionApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SOS Companion'), findsOneWidget);
    expect(find.text('Mulai Monitoring'), findsOneWidget);
    expect(find.text('Kontak Darurat'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
  });
}
