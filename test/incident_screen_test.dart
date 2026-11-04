import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/models/emergency_contact.dart';
import 'package:sos_companion/notifiers/incident_notifier.dart';
import 'package:sos_companion/repositories/emergency_contact_repository.dart';
import 'package:sos_companion/screens/history_screen.dart';
import 'package:sos_companion/screens/incident_screen.dart';
import 'package:sos_companion/services/location_service.dart';
import 'package:sos_companion/theme/app_theme.dart';

import 'support/fakes.dart';
import 'support/pump.dart';

const _cancelLabel = 'Batalkan (Ini Bukan Darurat)';

Future<IncidentLocation> _gpsOff() async =>
    throw StateError('Layanan lokasi perangkat sedang nonaktif.');

Future<IncidentLocation> _jakarta() async =>
    const IncidentLocation(-6.2088, 106.8456);

Widget _subject(
  FakeIncidentRepository repository, {
  FakeAlerts? alerts,
  EmergencyContact? contact,
  Future<IncidentLocation> Function()? location,
  bool openedFromHome = false,
  double textScale = 1,
}) {
  final screen = IncidentScreen(
    locationProvider: location ?? _gpsOff,
    alerts: alerts ?? FakeAlerts(),
  );
  return testApp(
    home: openedFromHome ? const _HomeWithButton() : screen,
    overrides: [
      incidentRepositoryProvider.overrideWithValue(repository),
      emergencyContactRepositoryProvider.overrideWithValue(
        FakeEmergencyContactRepository(contact: contact),
      ),
    ],
    routes: {
      '/history': (_) => const HistoryScreen(),
      '/incident': (_) => screen,
    },
    textScale: textScale,
  );
}

class _HomeWithButton extends StatelessWidget {
  const _HomeWithButton();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.pushNamed(context, '/incident'),
          child: const Text('Buka insiden'),
        ),
      );
}

Future<void> _runCountdown(WidgetTester tester) async {
  for (var second = 0; second < 10; second++) {
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('records the incident automatically when the countdown ends', (
    tester,
  ) async {
    final repository = FakeIncidentRepository();
    await tester.pumpWidget(_subject(repository));
    await _runCountdown(tester);

    expect(repository.stored, hasLength(1));
    expect(repository.stored.single.status, 'sent');
    expect(find.text('Riwayat Insiden'), findsOneWidget);
  });

  testWidgets('records a cancelled incident when the user cancels', (
    tester,
  ) async {
    final repository = FakeIncidentRepository();
    final alerts = FakeAlerts();
    await tester.pumpWidget(_subject(repository, alerts: alerts));

    await tester.tap(find.text(_cancelLabel));
    await tester.pumpAndSettle();

    expect(repository.stored.single.status, 'cancelled');
    expect(alerts.smsMessages, isEmpty);
  });

  testWidgets('the system back button counts as cancelling, not as silence', (
    tester,
  ) async {
    final repository = FakeIncidentRepository();
    final alerts = FakeAlerts();
    await tester.pumpWidget(
      _subject(repository, alerts: alerts, openedFromHome: true),
    );
    await tester.tap(find.text('Buka insiden'));
    await tester.pumpAndSettle();

    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();

    expect(repository.stored.single.status, 'cancelled');
    expect(alerts.smsMessages, isEmpty);
    expect(find.text('Buka insiden'), findsOneWidget);
  });

  testWidgets('the cancel button label is readable on its white background', (
    tester,
  ) async {
    await tester.pumpWidget(_subject(FakeIncidentRepository()));

    final labelColor = DefaultTextStyle.of(
      tester.element(find.text(_cancelLabel)),
    ).style.color;

    expect(labelColor, AppColors.danger);
    expect(labelColor, isNot(Colors.white));
  });

  testWidgets('does not overflow on a short landscape screen with 200% text', (
    tester,
  ) async {
    useScreenSize(tester, const Size(640, 360));
    await tester.pumpWidget(
      _subject(FakeIncidentRepository(), textScale: 2),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(_cancelLabel), findsOneWidget);
  });

  testWidgets('failed GPS stores null location, no fake map link, tells user', (
    tester,
  ) async {
    final repository = FakeIncidentRepository();
    final alerts = FakeAlerts();
    await tester.pumpWidget(
      _subject(repository, alerts: alerts, contact: testContact),
    );
    await _runCountdown(tester);

    final saved = repository.stored.single;
    expect(saved.latitude, isNull);
    expect(saved.longitude, isNull);
    expect(saved.hasLocation, isFalse);
    expect(alerts.smsMessages.single, isNot(contains('maps.google.com')));
    expect(alerts.smsMessages.single, contains('tidak tersedia'));
    expect(find.textContaining('Alert tetap dikirim tanpa lokasi'),
        findsOneWidget);
  });

  testWidgets('successful GPS stores coordinates and sends the map link', (
    tester,
  ) async {
    final repository = FakeIncidentRepository();
    final alerts = FakeAlerts();
    await tester.pumpWidget(_subject(
      repository,
      alerts: alerts,
      contact: testContact,
      location: _jakarta,
    ));
    await _runCountdown(tester);

    expect(repository.stored.single.latitude, -6.2088);
    expect(repository.stored.single.longitude, 106.8456);
    expect(alerts.smsMessages.single,
        contains('https://maps.google.com/?q=-6.2088,106.8456'));
  });

  testWidgets('denied notification permission is reported, SMS still opens', (
    tester,
  ) async {
    final repository = FakeIncidentRepository();
    final alerts = FakeAlerts(
      notificationFailure: 'Izin notifikasi belum diberikan.',
    );
    await tester.pumpWidget(
      _subject(repository, alerts: alerts, contact: testContact),
    );
    await _runCountdown(tester);

    expect(find.textContaining('Izin notifikasi belum diberikan'),
        findsOneWidget);
    expect(alerts.smsMessages, hasLength(1));
  });

  testWidgets('a storage failure does not stop the SMS alert', (tester) async {
    final repository = FakeIncidentRepository(failAdd: true);
    final alerts = FakeAlerts();
    await tester.pumpWidget(
      _subject(repository, alerts: alerts, contact: testContact),
    );
    await _runCountdown(tester);

    expect(alerts.smsMessages, hasLength(1));
    expect(find.textContaining('Riwayat insiden gagal disimpan'),
        findsOneWidget);
  });
}
