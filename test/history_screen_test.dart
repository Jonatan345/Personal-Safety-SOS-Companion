import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/models/incident.dart';
import 'package:sos_companion/notifiers/incident_notifier.dart';
import 'package:sos_companion/repositories/incident_repository.dart';
import 'package:sos_companion/screens/history_screen.dart';
import 'package:sos_companion/services/incident_api.dart';

class _FakeRepository extends IncidentRepository {
  _FakeRepository(
    List<Incident> initial, {
    this.failFirstLoad = false,
    this.loadGate,
    this.onSync,
  }) : stored = List<Incident>.of(initial);

  final List<Incident> stored;
  final bool failFirstLoad;
  final Completer<void>? loadGate;
  final Future<List<Incident>> Function()? onSync;
  final updated = <Incident>[];
  int loads = 0;

  @override
  bool get syncEnabled => onSync != null;

  @override
  Future<List<Incident>> getAllIncidents() async {
    loads++;
    if (failFirstLoad && loads == 1) throw StateError('gagal membaca');
    await loadGate?.future;
    return List<Incident>.of(stored);
  }

  @override
  Future<List<Incident>> syncFromServer() => onSync!();

  @override
  Future<Incident> addIncident(Incident incident) async {
    stored.add(incident);
    return incident;
  }

  @override
  Future<void> updateIncident(Incident incident) async {
    updated.add(incident);
  }

  @override
  Future<void> deleteIncident(String id) async {
    stored.removeWhere((incident) => incident.id == id);
  }
}

Widget _subject(IncidentRepository repository) => ProviderScope(
      overrides: [incidentRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: HistoryScreen()),
    );

final _sent = Incident(
  id: '1',
  timestamp: DateTime(2026, 10, 15, 5),
  latitude: -6.2088,
  longitude: 106.8456,
  status: 'sent',
);
final _cancelled = Incident(
  id: '2',
  timestamp: DateTime(2026, 10, 14, 9, 5),
  status: 'cancelled',
);

void main() {
  testWidgets('shows loading while history is read', (tester) async {
    final gate = Completer<void>();
    await tester.pumpWidget(_subject(_FakeRepository([], loadGate: gate)));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the empty state when there is no incident',
      (tester) async {
    await tester.pumpWidget(_subject(_FakeRepository([])));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada riwayat insiden'), findsOneWidget);
  });

  testWidgets('shows incidents with zero-padded time and honest location',
      (tester) async {
    await tester.pumpWidget(_subject(_FakeRepository([_sent, _cancelled])));
    await tester.pumpAndSettle();

    expect(find.text('15/10/2026 • 05:00'), findsOneWidget);
    expect(find.text('14/10/2026 • 09:05'), findsOneWidget);
    expect(find.text('-6.2088, 106.8456'), findsOneWidget);
    expect(find.text('Lokasi tidak diambil (dibatalkan)'), findsOneWidget);
    expect(find.text('0.0000, 0.0000'), findsNothing);
  });

  testWidgets('load error is in Indonesian, mentions the device, and retries',
      (tester) async {
    final repository = _FakeRepository([_sent], failFirstLoad: true);
    await tester.pumpWidget(_subject(repository));
    await tester.pumpAndSettle();

    expect(find.textContaining('dari perangkat'), findsOneWidget);
    expect(find.textContaining('server'), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('-6.2088, 106.8456'), findsOneWidget);
    expect(repository.loads, 2);
  });

  testWidgets('server sync failure keeps local data and explains in Indonesian',
      (tester) async {
    final repository = _FakeRepository(
      [_sent],
      onSync: () async => throw const IncidentApiException(
        'Unable to connect to the incidents API.',
        kind: IncidentApiErrorKind.network,
      ),
    );
    await tester.pumpWidget(_subject(repository));
    await tester.pumpAndSettle();

    expect(find.text('-6.2088, 106.8456'), findsOneWidget);
    expect(find.textContaining('Tidak dapat terhubung ke server'),
        findsOneWidget);
    expect(find.textContaining('Menampilkan riwayat dari perangkat'),
        findsOneWidget);
    expect(find.textContaining('Unable'), findsNothing);
  });

  testWidgets('server sync adds incidents that only exist on the server',
      (tester) async {
    final repository = _FakeRepository(
      [_sent],
      onSync: () async => [_sent, _cancelled],
    );
    await tester.pumpWidget(_subject(repository));
    await tester.pumpAndSettle();

    expect(find.text('Lokasi tidak diambil (dibatalkan)'), findsOneWidget);
    expect(find.textContaining('Tidak dapat terhubung'), findsNothing);
  });

  testWidgets('tapping a tile opens details and does not change the status',
      (tester) async {
    final repository = _FakeRepository([_sent]);
    await tester.pumpWidget(_subject(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('-6.2088, 106.8456'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Insiden'), findsOneWidget);
    expect(repository.updated, isEmpty);
  });

  testWidgets('changing the status is explicit from the detail sheet',
      (tester) async {
    final repository = _FakeRepository([_sent]);
    await tester.pumpWidget(_subject(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('-6.2088, 106.8456'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Ubah catatan menjadi'));
    await tester.pumpAndSettle();

    expect(repository.updated.single.status, 'cancelled');
    expect(find.text('Status catatan diperbarui.'), findsOneWidget);
  });

  testWidgets('delete asks for confirmation and can be undone',
      (tester) async {
    final repository = _FakeRepository([_sent]);
    await tester.pumpWidget(_subject(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('-6.2088, 106.8456'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus insiden'));
    await tester.pumpAndSettle();

    expect(find.text('Hapus insiden ini?'), findsOneWidget);
    expect(repository.stored, hasLength(1));

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(repository.stored, isEmpty);
    expect(find.text('Insiden dihapus.'), findsOneWidget);

    await tester.tap(find.text('Urungkan'));
    await tester.pumpAndSettle();

    expect(repository.stored, hasLength(1));
    expect(find.text('-6.2088, 106.8456'), findsOneWidget);
  });

  testWidgets('cancelling the delete dialog keeps the incident',
      (tester) async {
    final repository = _FakeRepository([_sent]);
    await tester.pumpWidget(_subject(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('-6.2088, 106.8456'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus insiden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(repository.stored, hasLength(1));
    expect(find.text('-6.2088, 106.8456'), findsOneWidget);
  });

  testWidgets('each tile is announced once with the full description',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_subject(_FakeRepository([_sent])));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp(
        r'^Insiden 15/10/2026 pukul 05:00, status terkirim, -6\.2088, 106\.8456$',
      )),
      findsOneWidget,
    );
    handle.dispose();
  });
}
