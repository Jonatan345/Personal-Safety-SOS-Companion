import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sos_companion/models/incident.dart';
import 'package:sos_companion/repositories/incident_repository.dart';
import 'package:sos_companion/services/incident_api.dart';

Incident _incident(
  String id,
  DateTime time, {
  double? latitude,
  double? longitude,
  String status = 'sent',
}) =>
    Incident(
      id: id,
      timestamp: time,
      latitude: latitude,
      longitude: longitude,
      status: status,
    );

void main() {
  late Directory testDirectory;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    testDirectory =
        await Directory.systemTemp.createTemp('sos_incident_repository_test_');
    Hive.init(testDirectory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async => testDirectory.path,
    );
    await Hive.openBox<String>(IncidentRepository.boxName);
  });

  tearDown(() async {
    await Hive.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await testDirectory.delete(recursive: true);
  });

  test('create then read returns incidents newest first', () async {
    final repository = IncidentRepository();
    await repository.addIncident(_incident('old', DateTime.utc(2026, 10, 1)));
    await repository.addIncident(_incident('new', DateTime.utc(2026, 10, 2)));

    final incidents = await repository.getAllIncidents();

    expect(incidents.map((incident) => incident.id), ['new', 'old']);
  });

  test('update persists the new status', () async {
    final repository = IncidentRepository();
    final time = DateTime.utc(2026, 10, 1);
    await repository.addIncident(_incident('a', time));

    await repository.updateIncident(_incident('a', time, status: 'cancelled'));

    final incidents = await repository.getAllIncidents();
    expect(incidents.single.status, 'cancelled');
  });

  test('delete removes only the selected incident', () async {
    final repository = IncidentRepository();
    await repository.addIncident(_incident('a', DateTime.utc(2026, 10, 1)));
    await repository.addIncident(_incident('b', DateTime.utc(2026, 10, 2)));

    await repository.deleteIncident('a');

    final incidents = await repository.getAllIncidents();
    expect(incidents.map((incident) => incident.id), ['b']);
  });

  test('incidents remain available after reopening the box', () async {
    final repository = IncidentRepository();
    await repository.addIncident(
      _incident('a', DateTime.utc(2026, 10, 1),
          latitude: -6.2088, longitude: 106.8456),
    );

    await Hive.box<String>(IncidentRepository.boxName).close();
    await Hive.openBox<String>(IncidentRepository.boxName);

    final incidents = await repository.getAllIncidents();
    expect(incidents.single.id, 'a');
    expect(incidents.single.latitude, -6.2088);
    expect(incidents.single.longitude, 106.8456);
  });

  test('an incident without location is stored as null, not 0,0', () async {
    final repository = IncidentRepository();
    await repository.addIncident(_incident('a', DateTime.utc(2026, 10, 1)));

    final stored = (await repository.getAllIncidents()).single;

    expect(stored.latitude, isNull);
    expect(stored.longitude, isNull);
    expect(stored.hasLocation, isFalse);
  });

  test('a corrupted record is skipped instead of failing the whole history',
      () async {
    final repository = IncidentRepository();
    await repository.addIncident(_incident('ok', DateTime.utc(2026, 10, 1)));
    await Hive.box<String>(IncidentRepository.boxName)
        .put('rusak', '{bukan-json');

    final incidents = await repository.getAllIncidents();

    expect(incidents.map((incident) => incident.id), ['ok']);
  });

  group('sinkronisasi dengan server', () {
    IncidentApi apiWith(MockClient client) => IncidentApi(
          baseUrl: 'https://api.example.test/api',
          client: client,
          requestTimeout: const Duration(milliseconds: 200),
        );

    test('syncEnabled hanya aktif jika API diatur', () {
      expect(IncidentRepository().syncEnabled, isFalse);
      expect(
        IncidentRepository(
          apiWith(MockClient((_) async => http.Response('[]', 200))),
        ).syncEnabled,
        isTrue,
      );
    });

    test('insiden yang hanya ada di server disimpan ke perangkat', () async {
      final remote = _incident('server', DateTime.utc(2026, 10, 3),
          latitude: -6.2, longitude: 106.8);
      final client = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode([remote.toJson()]), 200);
        }
        return http.Response('', 201);
      });
      final repository = IncidentRepository(apiWith(client));
      await repository.addIncident(_incident('lokal', DateTime.utc(2026, 10, 1)));

      final merged = await repository.syncFromServer();

      expect(merged.map((incident) => incident.id), ['server', 'lokal']);
      final cached = await repository.getAllIncidents();
      expect(cached.map((incident) => incident.id), contains('server'));
    });

    test('insiden yang hanya ada di perangkat dikirim ke server', () async {
      final posted = <String>[];
      final client = MockClient((request) async {
        if (request.method == 'GET') return http.Response('[]', 200);
        posted.add((jsonDecode(request.body) as Map)['id'] as String);
        return http.Response('', 201);
      });
      await Hive.box<String>(IncidentRepository.boxName).put(
        'lokal',
        jsonEncode(_incident('lokal', DateTime.utc(2026, 10, 1)).toJson()),
      );
      final repository = IncidentRepository(apiWith(client));

      await repository.syncFromServer();

      expect(posted, ['lokal']);
    });

    test('server tidak dapat dihubungi: error Indonesia, data lokal utuh',
        () async {
      final client = MockClient(
        (_) async => throw http.ClientException('offline'),
      );
      final repository = IncidentRepository(apiWith(client));
      await repository.addIncident(_incident('lokal', DateTime.utc(2026, 10, 1)));

      await expectLater(
        repository.syncFromServer(),
        throwsA(isA<IncidentApiException>().having(
          (error) => error.userMessage,
          'userMessage',
          contains('Tidak dapat terhubung ke server'),
        )),
      );
      final local = await repository.getAllIncidents();
      expect(local.map((incident) => incident.id), ['lokal']);
    });

    test('server lambat: timeout dilaporkan dan data lokal utuh', () async {
      final client = MockClient((_) => Completer<http.Response>().future);
      final repository = IncidentRepository(apiWith(client));
      await Hive.box<String>(IncidentRepository.boxName).put(
        'lokal',
        jsonEncode(_incident('lokal', DateTime.utc(2026, 10, 1)).toJson()),
      );

      await expectLater(
        repository.syncFromServer(),
        throwsA(isA<IncidentApiException>()
            .having((e) => e.kind, 'kind', IncidentApiErrorKind.timeout)),
      );
      expect((await repository.getAllIncidents()).single.id, 'lokal');
    });
  });
}
