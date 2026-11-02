import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/models/incident.dart';
import 'package:sos_companion/notifiers/incident_notifier.dart';
import 'package:sos_companion/repositories/incident_repository.dart';
import 'package:sos_companion/services/incident_api.dart';

class _FakeRepository extends IncidentRepository {
  _FakeRepository(
    this.stored, {
    this.firstReadGate,
    this.syncResult,
    this.syncError,
  });

  final List<Incident> stored;
  final Completer<void>? firstReadGate;
  final List<Incident>? syncResult;
  final Object? syncError;
  int _reads = 0;

  @override
  bool get syncEnabled => syncResult != null || syncError != null;

  @override
  Future<List<Incident>> getAllIncidents() async {
    // Hanya pembacaan pertama (refresh awal) yang ditahan.
    if (_reads++ == 0) await firstReadGate?.future;
    return List<Incident>.of(stored);
  }

  @override
  Future<List<Incident>> syncFromServer() async {
    final error = syncError;
    if (error != null) throw error;
    return syncResult!;
  }

  @override
  Future<Incident> addIncident(Incident incident) async {
    stored.add(incident);
    return incident;
  }
}

Incident _incident(String id, int day, {String status = 'sent'}) => Incident(
      id: id,
      timestamp: DateTime.utc(2026, 10, day),
      status: status,
    );

ProviderContainer _container(IncidentRepository repository) {
  final container = ProviderContainer(
    overrides: [incidentRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('adding an incident while history is still loading keeps old incidents',
      () async {
    final gate = Completer<void>();
    final repository =
        _FakeRepository([_incident('lama', 1)], firstReadGate: gate);
    final container = _container(repository);

    // Membuat notifier memulai refresh awal yang tertahan di gate.
    final notifier = container.read(incidentNotifierProvider.notifier);
    expect(container.read(incidentNotifierProvider).isLoading, isTrue);

    await notifier.addIncident(_incident('baru', 2, status: 'cancelled'));
    gate.complete();
    await pumpEventQueue();

    final ids = container
        .read(incidentNotifierProvider)
        .requireValue
        .map((incident) => incident.id)
        .toList();
    expect(ids, containsAll(['lama', 'baru']));
  });

  test('without an API the sync state stays idle', () async {
    final container = _container(_FakeRepository([_incident('lama', 1)]));

    container.read(incidentNotifierProvider.notifier);
    await pumpEventQueue();

    expect(container.read(incidentSyncProvider).phase, IncidentSyncPhase.idle);
  });

  test('sync success replaces the list with the merged server data', () async {
    final container = _container(_FakeRepository(
      [_incident('lama', 1)],
      syncResult: [_incident('server', 3), _incident('lama', 1)],
    ));

    container.read(incidentNotifierProvider.notifier);
    await pumpEventQueue();

    final ids = container
        .read(incidentNotifierProvider)
        .requireValue
        .map((incident) => incident.id)
        .toList();
    expect(ids, ['server', 'lama']);
    expect(container.read(incidentSyncProvider).phase, IncidentSyncPhase.idle);
  });

  test('sync failure keeps local incidents and reports an Indonesian warning',
      () async {
    final container = _container(_FakeRepository(
      [_incident('lama', 1)],
      syncError: const IncidentApiException(
        'Unable to connect to the incidents API.',
        kind: IncidentApiErrorKind.network,
      ),
    ));

    container.read(incidentNotifierProvider.notifier);
    await pumpEventQueue();

    final ids = container
        .read(incidentNotifierProvider)
        .requireValue
        .map((incident) => incident.id)
        .toList();
    expect(ids, ['lama']);

    final sync = container.read(incidentSyncProvider);
    expect(sync.phase, IncidentSyncPhase.failed);
    expect(sync.message, contains('Tidak dapat terhubung ke server'));
    expect(sync.message, isNot(contains('Unable')));
  });
}
