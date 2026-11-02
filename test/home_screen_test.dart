import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/screens/home_screen.dart';

void main() {
  const sizes = {
    '360x800': Size(360, 800),
    '800x1280': Size(800, 1280),
  };

  for (final entry in sizes.entries) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Home ${entry.key} dengan teks x$scale tanpa overflow',
          (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const HomeScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Mulai Monitoring'), findsOneWidget);
      });
    }
  }

  testWidgets('kartu menu dibacakan satu kali sebagai tombol', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.bySemanticsLabel('Kontak Darurat'), findsOneWidget);
    expect(find.bySemanticsLabel('Riwayat'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('kartu menu membuka rute yang sesuai', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const HomeScreen(),
        routes: {
          '/history': (_) => const Scaffold(body: Text('layar riwayat')),
        },
      ),
    );

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();

    expect(find.text('layar riwayat'), findsOneWidget);
  });
}
