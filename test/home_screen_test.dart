import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/models/emergency_contact.dart';
import 'package:sos_companion/repositories/emergency_contact_repository.dart';
import 'package:sos_companion/screens/home_screen.dart';

import 'support/fakes.dart';
import 'support/pump.dart';

Widget _subject(
  FakeEmergencyContactRepository repository, {
  Map<String, WidgetBuilder> routes = const {},
  double textScale = 1,
}) =>
    testApp(
      home: const HomeScreen(),
      overrides: [emergencyContactRepositoryProvider.overrideWithValue(repository)],
      routes: routes,
      textScale: textScale,
    );

void main() {
  const sizes = {
    '360x800': Size(360, 800),
    '800x1280': Size(800, 1280),
  };

  for (final entry in sizes.entries) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Home ${entry.key} dengan teks x$scale tanpa overflow',
          (tester) async {
        useScreenSize(tester, entry.value);
        await tester.pumpWidget(_subject(
          FakeEmergencyContactRepository(),
          textScale: scale,
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Mulai Monitoring'), findsOneWidget);
      });
    }
  }

  testWidgets('menampilkan kontak darurat nyata yang tersimpan',
      (tester) async {
    await tester.pumpWidget(
      _subject(FakeEmergencyContactRepository(contact: testContact)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alert akan disiapkan untuk Ibu Sari.'), findsOneWidget);
    expect(find.text('Atur Kontak Darurat'), findsNothing);
  });

  testWidgets('memperingatkan jika belum ada kontak dan menuju layar kontak',
      (tester) async {
    await tester.pumpWidget(_subject(
      FakeEmergencyContactRepository(),
      routes: {
        '/contact-setup': (_) => const Scaffold(body: Text('layar kontak')),
      },
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Belum ada kontak darurat'), findsOneWidget);

    await tester.tap(find.text('Atur Kontak Darurat'));
    await tester.pumpAndSettle();

    expect(find.text('layar kontak'), findsOneWidget);
  });

  testWidgets('menampilkan status memeriksa saat kontak masih dimuat',
      (tester) async {
    final pending = Completer<EmergencyContact?>();
    await tester.pumpWidget(
      _subject(FakeEmergencyContactRepository(onFetch: () => pending.future)),
    );
    await tester.pump();

    expect(find.text('Memeriksa kontak darurat…'), findsOneWidget);
  });

  testWidgets('menampilkan pesan jika kontak tidak dapat dimuat',
      (tester) async {
    await tester.pumpWidget(_subject(FakeEmergencyContactRepository(
      onFetch: () async => throw StateError('gagal membaca'),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Kontak darurat tidak dapat dimuat.'), findsOneWidget);
    expect(find.text('Atur Kontak Darurat'), findsOneWidget);
  });

  testWidgets('kartu menu dibacakan satu kali sebagai tombol', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_subject(FakeEmergencyContactRepository()));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Kontak Darurat'), findsOneWidget);
    expect(find.bySemanticsLabel('Riwayat'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('kartu menu membuka rute yang sesuai', (tester) async {
    await tester.pumpWidget(_subject(
      FakeEmergencyContactRepository(),
      routes: {'/history': (_) => const Scaffold(body: Text('layar riwayat'))},
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();

    expect(find.text('layar riwayat'), findsOneWidget);
  });
}
