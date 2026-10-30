import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sos_companion/models/emergency_contact.dart';
import 'package:sos_companion/models/incident.dart';
import 'package:sos_companion/notifiers/incident_notifier.dart';
import 'package:sos_companion/repositories/emergency_contact_repository.dart';
import 'package:sos_companion/repositories/incident_repository.dart';
import 'package:sos_companion/screens/history_screen.dart';
import 'package:sos_companion/screens/incident_screen.dart';
import 'package:sos_companion/services/alert_service.dart';
import 'package:sos_companion/services/incident_api.dart';
import 'package:sos_companion/services/location_service.dart';

class FakeIncidentRepository extends IncidentRepository {
  FakeIncidentRepository()
      : super(
          IncidentApi(
            baseUrl: 'https://api.example.test',
            client: MockClient((_) async => http.Response('[]', 200)),
          ),
        );

  final List<Incident> incidents = [];

  @override
  Future<List<Incident>> getAllIncidents() async =>
      List<Incident>.of(incidents);

  @override
  Future<Incident> addIncident(Incident incident) async {
    incidents.add(incident);
    return incident;
  }

  @override
  Future<void> updateIncident(Incident incident) async {}

  @override
  Future<void> deleteIncident(String id) async {
    incidents.removeWhere((incident) => incident.id == id);
  }
}

class FakeEmergencyContactRepository implements EmergencyContactRepository {
  FakeEmergencyContactRepository([this.contact]);
  final EmergencyContact? contact;

  @override
  Future<EmergencyContact?> fetchContact() async => contact;

  @override
  Future<EmergencyContact> saveContact(EmergencyContactDraft draft) =>
      throw UnimplementedError();
}

class FakeAlerts implements AlertGateway {
  FakeAlerts({this.notificationFailure, this.smsFailure});
  final String? notificationFailure;
  final String? smsFailure;
  final notifications = <String>[];
  final smsMessages = <String>[];

  @override
  Future<String?> showEmergencyNotification(String body) async {
    notifications.add(body);
    return notificationFailure;
  }

  @override
  Future<String?> openSmsComposer({
    required String phone,
    required String message,
  }) async {
    smsMessages.add(message);
    return smsFailure;
  }
}

const _contact = EmergencyContact(
  id: 'c1',
  name: 'Ibu Sari',
  phoneNumber: '081234567890',
);

Future<IncidentLocation> _gpsOff() async =>
    throw StateError('Layanan lokasi perangkat sedang nonaktif.');

Widget createSubject(
  FakeIncidentRepository repository, {
  FakeAlerts? alerts,
  EmergencyContact? contact,
  Future<IncidentLocation> Function()? location,
}) {
  return ProviderScope(
    overrides: [
      incidentRepositoryProvider.overrideWithValue(repository),
      emergencyContactRepositoryProvider.overrideWithValue(
        FakeEmergencyContactRepository(contact),
      ),
    ],
    child: MaterialApp(
      home: IncidentScreen(
        locationProvider: location ?? _gpsOff,
        alerts: alerts ?? FakeAlerts(),
      ),
      routes: {'/history': (_) => const HistoryScreen()},
    ),
  );
}

Future<void> runCountdown(WidgetTester tester) async {
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
    await tester.pumpWidget(createSubject(repository));
    await runCountdown(tester);

    expect(repository.incidents, hasLength(1));
    expect(repository.incidents.single.status, 'sent');
    expect(find.text('Riwayat Insiden'), findsOneWidget);
  });

  testWidgets('records a cancelled incident when the user cancels', (
    tester,
  ) async {
    final repository = FakeIncidentRepository();
    final alerts = FakeAlerts();
    await tester.pumpWidget(createSubject(repository, alerts: alerts));

    await tester.tap(find.text('Batalkan (Ini Bukan Darurat)'));
    await tester.pumpAndSettle();

    expect(repository.incidents, hasLength(1));
    expect(repository.incidents.single.status, 'cancelled');
    expect(alerts.smsMessages, isEmpty);
  });

  testWidgets('failed GPS stores null location, no fake map link, tells user', (
    tester,
  ) async {
    final repository = FakeIncidentRepository();
    final alerts = FakeAlerts();
    await tester.pumpWidget(
      createSubject(repository, alerts: alerts, contact: _contact),
    );
    await runCountdown(tester);

    final saved = repository.incidents.single;
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
    await tester.pumpWidget(createSubject(
      repository,
      alerts: alerts,
      contact: _contact,
      location: () async => const IncidentLocation(-6.2088, 106.8456),
    ));
    await runCountdown(tester);

    expect(repository.incidents.single.latitude, -6.2088);
    expect(repository.incidents.single.longitude, 106.8456);
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
      createSubject(repository, alerts: alerts, contact: _contact),
    );
    await runCountdown(tester);

    expect(find.textContaining('Izin notifikasi belum diberikan'),
        findsOneWidget);
    expect(alerts.smsMessages, hasLength(1));
  });
}
