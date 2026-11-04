import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/models/incident.dart';
import 'package:sos_companion/notifiers/incident_notifier.dart';
import 'package:sos_companion/services/incident_api.dart';

import 'support/fakes.dart';

Incident _incident(String id, int day, {String status = 'sent'}) =>
    buildIncident(id: id, timestamp: DateTime.utc(2026, 10, day), status: status);

ProviderContainer _container(FakeIncidentRepository repository) {
  final container = ProviderContainer(
    overrides: [incidentRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

List<String> _ids(ProviderContainer container) => container
    .read(incidentNotifierProvider)
    .requireValue
    .map((incident) => incident.id)
    .toList();

void main() {
  group('memuat dan menambah', () {
    test('adding an incident while history is still loading keeps old ones',
        () async {
      final gate = Completer<void>();
      final container = _container(FakeIncidentRepository(
        initial: [_incident('lama', 1)],
        firstReadGate: gate,
      ));

      final notifier = container.read(incidentNotifierProvider.notifier);
      expect(container.read(incidentNotifierProvider).isLoading, isTrue);

      await notifier.addIncident(_incident('baru', 2, status: 'cancelled'));
      gate.complete();
      await pumpEventQueue();

      expect(_ids(container), containsAll(['lama', 'baru']));
    });
  });

  group('mengubah dan menghapus', () {
    test('updateStatus changes only the selected incident', () async {
      final repository = FakeIncidentRepository(
        initial: [_incident('a', 1), _incident('b', 2)],
      );
      final container = _container(repository);
      final notifier = container.read(incidentNotifierProvider.notifier);
      await pumpEventQueue();

      await notifier.updateStatus('a', 'cancelled');

      final byId = {
        for (final incident
            in container.read(incidentNotifierProvider).requireValue)
          incident.id: incident.status,
      };
      expect(byId, {'a': 'cancelled', 'b': 'sent'});
      expect(repository.updated.single.id, 'a');
    });

    test('deleteIncident removes only the selected incident', () async {
      final container = _container(FakeIncidentRepository(
        initial: [_incident('a', 1), _incident('b', 2)],
      ));
      final notifier = container.read(incidentNotifierProvider.notifier);
      await pumpEventQueue();

      await notifier.deleteIncident('a');

      expect(_ids(container), ['b']);
    });

    test('a failed delete rethrows and restores the previous list', () async {
      final container = _container(FakeIncidentRepository(
        initial: [_incident('a', 1)],
        failMutations: true,
      ));
      final notifier = container.read(incidentNotifierProvider.notifier);
      await pumpEventQueue();

      await expectLater(notifier.deleteIncident('a'), throwsStateError);

      expect(_ids(container), ['a']);
    });

    test('updating an unknown id changes nothing', () async {
      final repository = FakeIncidentRepository(initial: [_incident('a', 1)]);
      final container = _container(repository);
      final notifier = container.read(incidentNotifierProvider.notifier);
      await pumpEventQueue();

      await notifier.updateStatus('tidak-ada', 'cancelled');

      expect(_ids(container), ['a']);
      expect(repository.updated, isEmpty);
    });
  });

  group('sinkronisasi dengan server', () {
    test('without an API the sync state stays idle', () async {
      final container =
          _container(FakeIncidentRepository(initial: [_incident('lama', 1)]));

      container.read(incidentNotifierProvider.notifier);
      await pumpEventQueue();

      expect(
          container.read(incidentSyncProvider).phase, IncidentSyncPhase.idle);
    });

    test('sync success replaces the list with the merged server data',
        () async {
      final container = _container(FakeIncidentRepository(
        initial: [_incident('lama', 1)],
        onSync: () async => [_incident('server', 3), _incident('lama', 1)],
      ));

      container.read(incidentNotifierProvider.notifier);
      await pumpEventQueue();

      expect(_ids(container), ['server', 'lama']);
      expect(
          container.read(incidentSyncProvider).phase, IncidentSyncPhase.idle);
    });

    test('sync failure keeps local incidents and reports an Indonesian warning',
        () async {
      final container = _container(FakeIncidentRepository(
        initial: [_incident('lama', 1)],
        onSync: () async => throw const IncidentApiException(
          'Unable to connect to the incidents API.',
          kind: IncidentApiErrorKind.network,
        ),
      ));

      container.read(incidentNotifierProvider.notifier);
      await pumpEventQueue();

      expect(_ids(container), ['lama']);
      final sync = container.read(incidentSyncProvider);
      expect(sync.phase, IncidentSyncPhase.failed);
      expect(sync.message, contains('Tidak dapat terhubung ke server'));
      expect(sync.message, isNot(contains('Unable')));
    });
  });
}
