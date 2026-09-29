import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/models/emergency_contact.dart';
import 'package:sos_companion/repositories/emergency_contact_repository.dart';
import 'package:sos_companion/screens/contact_setup_screen.dart';

class FakeEmergencyContactRepository implements EmergencyContactRepository {
  FakeEmergencyContactRepository({this.onFetch, this.onSave});

  Future<EmergencyContact?> Function()? onFetch;
  Future<EmergencyContact> Function(EmergencyContactDraft draft)? onSave;

  @override
  Future<EmergencyContact?> fetchContact() =>
      onFetch?.call() ?? Future.value(null);

  @override
  Future<EmergencyContact> saveContact(EmergencyContactDraft draft) {
    return onSave?.call(draft) ??
        Future.value(EmergencyContact(
            id: '1', name: draft.name, phoneNumber: draft.phoneNumber));
  }
}

Widget createSubject(EmergencyContactRepository repository) {
  return ProviderScope(
    overrides: [
      emergencyContactRepositoryProvider.overrideWithValue(repository)
    ],
    child: const MaterialApp(home: ContactSetupScreen()),
  );
}

void main() {
  testWidgets('shows initial loading while contact data is fetched',
      (tester) async {
    final completer = Completer<EmergencyContact?>();
    await tester.pumpWidget(
      createSubject(
          FakeEmergencyContactRepository(onFetch: () => completer.future)),
    );

    expect(find.byKey(const Key('contact-initial-loading')), findsOneWidget);
  });

  testWidgets('shows empty state when no contact has been saved',
      (tester) async {
    await tester.pumpWidget(createSubject(FakeEmergencyContactRepository()));
    await tester.pump();

    expect(find.byKey(const Key('contact-empty-state')), findsOneWidget);
    expect(find.text('Belum ada kontak darurat'), findsOneWidget);
  });

  testWidgets('shows loaded data when a contact exists', (tester) async {
    final contact =
        EmergencyContact(id: '1', name: 'Ibu Sari', phoneNumber: '112');
    await tester.pumpWidget(
      createSubject(
          FakeEmergencyContactRepository(onFetch: () => Future.value(contact))),
    );
    await tester.pump();

    expect(find.byKey(const Key('contact-data-state')), findsOneWidget);
    expect(find.text('Ibu Sari'), findsOneWidget);
    expect(find.text('112'), findsOneWidget);
  });

  testWidgets('shows error state and retry loads the contact again',
      (tester) async {
    var requestCount = 0;
    final repository = FakeEmergencyContactRepository(
      onFetch: () {
        requestCount++;
        if (requestCount == 1) return Future.error(Exception('offline'));
        return Future.value(null);
      },
    );

    await tester.pumpWidget(createSubject(repository));
    await tester.pump();

    expect(find.byKey(const Key('contact-load-error')), findsOneWidget);
    await tester.tap(find.byKey(const Key('contact-retry-button')));
    await tester.pump();

    expect(find.byKey(const Key('contact-empty-state')), findsOneWidget);
    expect(requestCount, 2);
  });

  testWidgets('validates required name and short phone number', (tester) async {
    await tester.pumpWidget(createSubject(FakeEmergencyContactRepository()));
    await tester.pump();
    await tester.tap(find.text('Tambah Kontak Darurat'));
    await tester.pump();
    await tester.tap(find.text('Simpan Kontak'));
    await tester.pump();

    expect(find.text('Nama wajib diisi'), findsOneWidget);
    expect(find.text('Masukkan minimal 3 digit'), findsOneWidget);
  });

  testWidgets('shows submit loading and prevents a double submit',
      (tester) async {
    final saveCompleter = Completer<EmergencyContact>();
    var saveCount = 0;
    final repository = FakeEmergencyContactRepository(
      onSave: (_) {
        saveCount++;
        return saveCompleter.future;
      },
    );

    await tester.pumpWidget(createSubject(repository));
    await tester.pump();
    await tester.tap(find.text('Tambah Kontak Darurat'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(0), 'Ibu Sari');
    await tester.enterText(find.byType(TextFormField).at(1), '911');

    await tester.tap(find.text('Simpan Kontak'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
    expect(saveCount, 1);

    saveCompleter.complete(
        const EmergencyContact(id: '1', name: 'Ibu Sari', phoneNumber: '911'));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('contact-data-state')), findsOneWidget);
  });
}
