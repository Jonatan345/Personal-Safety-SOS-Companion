import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/models/incident.dart';
import 'package:sos_companion/notifiers/incident_notifier.dart';
import 'package:sos_companion/repositories/incident_repository.dart';
import 'package:sos_companion/screens/history_screen.dart';
import 'package:sos_companion/screens/incident_screen.dart';

class FakeIncidentRepository extends IncidentRepository {
  final List<Incident> incidents = [];

  @override
  List<Incident> getAllIncidents() => List<Incident>.of(incidents);

  @override
  Future<void> addIncident(Incident incident) async {
    incidents.add(incident);
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
