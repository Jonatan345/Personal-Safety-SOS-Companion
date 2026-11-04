import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/models/emergency_contact.dart';
import 'package:sos_companion/repositories/emergency_contact_repository.dart';
import 'package:sos_companion/screens/contact_setup_screen.dart';

import 'support/fakes.dart';
import 'support/pump.dart';

const _failureMessage = 'Kontak gagal disimpan. Silakan coba lagi.';
const _successMessage = 'Kontak darurat berhasil disimpan';

Future<void> _pumpScreen(
  WidgetTester tester,
  EmergencyContactRepository repository, {
  Size size = const Size(400, 1000),
  double textScale = 1,
}) async {
  useScreenSize(tester, size);
  await tester.pumpWidget(testApp(
    home: const ContactSetupScreen(),
    overrides: [emergencyContactRepositoryProvider.overrideWithValue(repository)],
    textScale: textScale,
  ));
}

Future<void> _openFormFromEmptyState(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Tambah Kontak Darurat'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Tambah Kontak Darurat'));
  await tester.pumpAndSettle();
}

Future<void> _fillForm(
  WidgetTester tester, {
  String name = 'Ibu Sari',
  String phone = '911',
}) async {
  await tester.enterText(find.byType(TextFormField).at(0), name);
  await tester.enterText(find.byType(TextFormField).at(1), phone);
  await tester.pump();
}

String? _fieldText(WidgetTester tester, int index) {
  return tester
      .widget<TextFormField>(find.byType(TextFormField).at(index))
      .controller
      ?.text;
}

Future<FakeEmergencyContactRepository> _pumpEmptyWithForm(
  WidgetTester tester, {
  Future<EmergencyContact> Function(EmergencyContactDraft draft)? onSave,
  Size size = const Size(400, 1000),
  double textScale = 1,
}) async {
  final repository = FakeEmergencyContactRepository(onSave: onSave);
  await _pumpScreen(tester, repository, size: size, textScale: textScale);
  await tester.pumpAndSettle();
  await _openFormFromEmptyState(tester);
  return repository;
}

void main() {
  group('kondisi UI wajib (P4)', () {
    testWidgets('shows initial loading while contact data is fetched',
        (tester) async {
      final pending = Completer<EmergencyContact?>();
      await _pumpScreen(
        tester,
        FakeEmergencyContactRepository(onFetch: () => pending.future),
      );
      await tester.pump();

      expect(find.byKey(const Key('contact-initial-loading')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows loaded data when a contact exists', (tester) async {
      await _pumpScreen(
        tester,
        FakeEmergencyContactRepository(contact: testContact),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('contact-data-state')), findsOneWidget);
      expect(find.text('Ibu Sari'), findsOneWidget);
      expect(find.text('081234567890'), findsOneWidget);
    });

    testWidgets('shows empty state when no contact has been saved',
        (tester) async {
      await _pumpScreen(tester, FakeEmergencyContactRepository());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('contact-empty-state')), findsOneWidget);
      expect(find.text('Belum ada kontak darurat'), findsOneWidget);
    });

    testWidgets('shows error state and retry loads the contact again',
        (tester) async {
      var attempts = 0;
      await _pumpScreen(
        tester,
        FakeEmergencyContactRepository(onFetch: () async {
          attempts++;
          if (attempts == 1) throw StateError('gagal membaca');
          return testContact;
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('contact-load-error')), findsOneWidget);

      await tester.tap(find.byKey(const Key('contact-retry-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('contact-data-state')), findsOneWidget);
      expect(attempts, 2);
    });

    testWidgets('validates required name and short phone number',
        (tester) async {
      final repository = await _pumpEmptyWithForm(tester);

      await _fillForm(tester, name: '', phone: '12');
      await tester.tap(find.text('Simpan Kontak'));
      await tester.pump();

      expect(find.text('Nama wajib diisi'), findsOneWidget);
      expect(find.text('Masukkan minimal 3 digit'), findsOneWidget);
      expect(repository.saveCalls, 0);
    });

    testWidgets('shows submit loading and prevents a double submit',
        (tester) async {
      final saving = Completer<EmergencyContact>();
      final repository =
          await _pumpEmptyWithForm(tester, onSave: (_) => saving.future);

      await _fillForm(tester);
      await tester.tap(find.text('Simpan Kontak'));
      await tester.pump();

      expect(find.text('Menyimpan kontak...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      expect(repository.saveCalls, 1);

      saving.complete(testContact);
      await tester.pumpAndSettle();
    });
  });

  group('kontrak perilaku form (P9)', () {
    testWidgets('a name made only of spaces is rejected before any request',
        (tester) async {
      final repository = await _pumpEmptyWithForm(tester);

      await _fillForm(tester, name: '   ', phone: '911');
      await tester.tap(find.text('Simpan Kontak'));
      await tester.pump();

      expect(find.text('Nama wajib diisi'), findsOneWidget);
      expect(repository.saveCalls, 0);
    });

    testWidgets('a successful save shows the confirmation and the contact',
        (tester) async {
      final repository = await _pumpEmptyWithForm(tester);

      await _fillForm(tester);
      await tester.tap(find.text('Simpan Kontak'));
      await tester.pumpAndSettle();

      expect(repository.saveCalls, 1);
      expect(find.text(_successMessage), findsOneWidget);
      expect(find.byKey(const Key('contact-data-state')), findsOneWidget);
      expect(find.text('Ibu Sari'), findsOneWidget);
    });

    testWidgets('a failed save explains why, keeps the input and can retry',
        (tester) async {
      var attempts = 0;
      final repository = await _pumpEmptyWithForm(
        tester,
        onSave: (draft) async {
          attempts++;
          if (attempts == 1) throw StateError('server gagal');
          return EmergencyContact(
            id: '1',
            name: draft.name,
            phoneNumber: draft.phoneNumber,
          );
        },
      );

      await _fillForm(tester, name: 'Ibu Sari', phone: '081234567890');
      await tester.tap(find.text('Simpan Kontak'));
      await tester.pumpAndSettle();

      expect(find.text(_failureMessage), findsNWidgets(2));
      expect(find.text(_successMessage), findsNothing);
      expect(_fieldText(tester, 0), 'Ibu Sari');
      expect(_fieldText(tester, 1), '081234567890');

      await tester.tap(find.text('Simpan Kontak'));
      await tester.pumpAndSettle();

      expect(repository.saveCalls, 2);
      expect(find.byKey(const Key('contact-data-state')), findsOneWidget);
      expect(find.text(_successMessage), findsOneWidget);
    });

    testWidgets('a failed edit of an existing contact is not shown as success',
        (tester) async {
      final repository = FakeEmergencyContactRepository(
        contact: testContact,
        onSave: (_) async => throw StateError('server gagal'),
      );
      await _pumpScreen(tester, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ubah Kontak'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Kontak'));
      await tester.pumpAndSettle();

      expect(find.text(_failureMessage), findsNWidgets(2));
      expect(find.text(_successMessage), findsNothing);
      expect(find.byKey(const Key('contact-form')), findsOneWidget);
    });

    testWidgets('typed values survive a change of screen width',
        (tester) async {
      await _pumpEmptyWithForm(tester);
      await _fillForm(tester, name: 'Ibu Sari', phone: '911');

      tester.view.physicalSize = const Size(900, 1000);
      await tester.pumpAndSettle();

      expect(_fieldText(tester, 0), 'Ibu Sari');
      expect(_fieldText(tester, 1), '911');
    });
  });

  group('responsif dan aksesibel (P8)', () {
    testWidgets('stacks the summary under the form on narrow screens',
        (tester) async {
      await _pumpEmptyWithForm(tester, size: const Size(400, 1000));

      final form = tester.getRect(find.byKey(const Key('contact-form')));
      final summary = tester.getRect(find.byKey(const Key('contact-summary')));

      expect(summary.top, greaterThanOrEqualTo(form.bottom));
    });

    testWidgets('puts the summary beside the form on wide screens',
        (tester) async {
      await _pumpEmptyWithForm(tester, size: const Size(900, 1000));

      final form = tester.getRect(find.byKey(const Key('contact-form')));
      final summary = tester.getRect(find.byKey(const Key('contact-summary')));

      expect(summary.left, greaterThanOrEqualTo(form.right));
      expect((summary.top - form.top).abs(), lessThan(1));
    });

    testWidgets('keeps the save button reachable when the keyboard is open',
        (tester) async {
      await _pumpEmptyWithForm(tester, size: const Size(400, 800));

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Simpan Kontak'));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.text('Simpan Kontak')).bottom,
        lessThanOrEqualTo(800 - 300),
      );
    });

    testWidgets('does not overflow with 200% text on a small phone',
        (tester) async {
      await _pumpEmptyWithForm(
        tester,
        size: const Size(360, 800),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Simpan Kontak'), findsOneWidget);
    });
  });
}
