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

Widget createSubject(
  EmergencyContactRepository repository, {
  double textScale = 1,
}) {
  return ProviderScope(
    overrides: [
      emergencyContactRepositoryProvider.overrideWithValue(repository)
    ],
    child: MaterialApp(
      home: const ContactSetupScreen(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
    ),
  );
}

void main() {
  testWidgets('uses stacked form and summary on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createSubject(FakeEmergencyContactRepository()));
    await tester.pump();
    await tester.tap(find.text('Tambah Kontak Darurat'));
    await tester.pump();

    final form = tester.getRect(find.byKey(const Key('contact-form')));
    final summary = tester.getRect(find.byKey(const Key('contact-summary')));
    expect(summary.top, greaterThan(form.bottom));
  });

  testWidgets('uses two columns and keeps values when resized wide',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createSubject(FakeEmergencyContactRepository()));
    await tester.pump();
    await tester.tap(find.text('Tambah Kontak Darurat'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(0), 'Ibu Sari');
    await tester.enterText(find.byType(TextFormField).at(1), '08123456789');

    tester.view.physicalSize = const Size(800, 1280);
    await tester.pumpAndSettle();

    final form = tester.getRect(find.byKey(const Key('contact-form')));
    final summary = tester.getRect(find.byKey(const Key('contact-summary')));
    expect(summary.left, greaterThan(form.right));
    expect(
      find.descendant(
        of: find.byKey(const Key('contact-summary')),
        matching: find.text('Ibu Sari'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('contact-summary')),
        matching: find.text('08123456789'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps the last field and save action reachable with keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(createSubject(FakeEmergencyContactRepository()));
    await tester.pump();
    await tester.tap(find.text('Tambah Kontak Darurat'));
    await tester.pump();
    final phoneField = find.byType(TextFormField).at(1);
    await tester.tap(phoneField);
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
    expect(find.text('Nomor Telepon'), findsOneWidget);
    expect(find.text('Simpan Kontak'), findsOneWidget);
    expect(
      tester.getRect(find.text('Simpan Kontak')).bottom,
      lessThanOrEqualTo(480),
    );
  });

  testWidgets('shows initial loading while contact data is fetched',
      (tester) async {
    final completer = Completer<EmergencyContact?>();
    await tester.pumpWidget(
      createSubject(
          FakeEmergencyContactRepository(onFetch: () => completer.future)),
    );

    expect(find.byKey(const Key('contact-initial-loading')), findsOneWidget);
  });

  testWidgets('keeps form controls usable with 200 percent text scaling',
      (tester) async {
    await tester.pumpWidget(
      createSubject(FakeEmergencyContactRepository(), textScale: 2),
    );
    await tester.pump();
    await tester.tap(find.text('Tambah Kontak Darurat'));
    await tester.pumpAndSettle();

    expect(find.text('Nama Kontak'), findsOneWidget);
    expect(find.text('Nomor Telepon'), findsOneWidget);
    expect(find.text('Simpan Kontak'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(find.text('Menyimpan kontak...'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
    expect(saveCount, 1);

    saveCompleter.complete(
        const EmergencyContact(id: '1', name: 'Ibu Sari', phoneNumber: '911'));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('contact-data-state')), findsOneWidget);
  });

  testWidgets('shows inline and snackbar feedback when saving fails',
      (tester) async {
    final repository = FakeEmergencyContactRepository(
      onSave: (_) => Future.error(Exception('offline')),
    );
    await tester.pumpWidget(createSubject(repository));
    await tester.pump();
    await tester.tap(find.text('Tambah Kontak Darurat'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(0), 'Ibu Sari');
    await tester.enterText(find.byType(TextFormField).at(1), '08123456789');

    await tester.tap(find.text('Simpan Kontak'));
    await tester.pumpAndSettle();

    expect(
      find.text('Kontak gagal disimpan. Silakan coba lagi.'),
      findsNWidgets(2),
    );
    expect(find.byKey(const Key('contact-form')), findsOneWidget);
  });
}
