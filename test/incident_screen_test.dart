import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sos_companion/models/incident.dart';
import 'package:sos_companion/notifiers/incident_notifier.dart';
import 'package:sos_companion/repositories/incident_repository.dart';
import 'package:sos_companion/services/incident_api.dart';
import 'package:sos_companion/screens/history_screen.dart';
import 'package:sos_companion/screens/incident_screen.dart';

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

Widget createSubject(FakeIncidentRepository repository) {
  return ProviderScope(
    overrides: [incidentRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      home: const IncidentScreen(),
      routes: {'/history': (_) => const HistoryScreen()},
    ),
  );
}

void main() {
  testWidgets('records the incident automatically when the countdown ends', (
    tester,
  ) async {
    final repository = FakeIncidentRepository();
    await tester.pumpWidget(createSubject(repository));

    for (var second = 0; second < 10; second++) {
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
    }

    expect(repository.incidents, hasLength(1));
    expect(repository.incidents.single.status, 'sent');
    expect(find.text('Riwayat Insiden'), findsOneWidget);
  });

  testWidgets('records a cancelled incident when the user cancels', (
    tester,
  ) async {
    final repository = FakeIncidentRepository();
    await tester.pumpWidget(createSubject(repository));

    await tester.tap(find.text('Batalkan (Ini Bukan Darurat)'));
    await tester.pumpAndSettle();

    expect(repository.incidents, hasLength(1));
    expect(repository.incidents.single.status, 'cancelled');
  });
}
