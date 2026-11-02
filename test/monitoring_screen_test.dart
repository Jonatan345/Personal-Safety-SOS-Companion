import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sos_companion/screens/monitoring_screen.dart';
import 'package:sos_companion/services/monitoring_service.dart';
import 'package:sos_companion/services/permission_service.dart';

class FakePermissionService extends PermissionService {
  FakePermissionService(
    this.request, {
    this.notification = const NotificationPermissionResult(
      status: PermissionStatus.granted,
    ),
  });

  final Future<PermissionResult> Function() request;
  final NotificationPermissionResult notification;

  @override
  Future<PermissionResult> requestMonitoringPermissions() => request();

  // Tanpa override ini, test memanggil plugin asli dan meninggalkan timer 12 detik.
  @override
  Future<NotificationPermissionResult> requestNotificationPermission() async =>
      notification;
}

class FakeMonitoringController implements MonitoringController {
  FakeMonitoringController({
    required this.startResult,
    required this.onTrigger,
    required this.onError,
    required this.events,
  });

  final Future<void> startResult;
  final void Function(TriggerSource source) onTrigger;
  final MonitoringErrorCallback onError;
  final List<String> events;
  int disposeCount = 0;

  @override
  Future<void> start() {
    events.add('start');
    return startResult;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
    events.add('dispose');
  }

  @override
  void simulateMotion() => onTrigger(TriggerSource.motion);
}

const _granted = PermissionResult(microphone: PermissionStatus.granted);
const _denied = PermissionResult(microphone: PermissionStatus.denied);

Widget _subject({
  required PermissionService permissions,
  required MonitoringServiceFactory factory,
  Map<String, WidgetBuilder> routes = const {},
}) {
  return MaterialApp(
    home: MonitoringScreen(
      permissionService: permissions,
      monitoringFactory: factory,
    ),
    routes: routes,
  );
}

void main() {
  test('sensor streams can start without waiting for their first reading',
      () async {
    final accelerometer = StreamController<AccelerometerEvent>.broadcast();
    final microphone = StreamController<NoiseReading>.broadcast();
    Object? sensorError;
    final service = MonitoringService(
      onTrigger: (_) {},
      onError: (error) => sensorError = error,
      accelerometerStream: () => accelerometer.stream,
      noiseStream: () => microphone.stream,
    );

    await service.start().timeout(const Duration(seconds: 1));
    service.simulateMotion();
    expect(sensorError, isNull);

    await service.dispose();
    await accelerometer.close();
    await microphone.close();
  });

  testWidgets('shows a recoverable message when microphone is denied',
      (tester) async {
    await tester.pumpWidget(_subject(
      permissions: FakePermissionService(() async => _denied),
      factory: _unusedFactory,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Izin mikrofon diperlukan'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('permission timeout exits loading with a retry action',
      (tester) async {
    final pendingPermission = Completer<PermissionResult>();
    await tester.pumpWidget(_subject(
      permissions: FakePermissionService(() => pendingPermission.future),
      factory: _unusedFactory,
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 26));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('batas waktu'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('sensor startup timeout exits loading and disposes the sensor',
      (tester) async {
    late FakeMonitoringController controller;
    await tester.pumpWidget(_subject(
      permissions: FakePermissionService(() async => _granted),
      factory: ({required onTrigger, required onError}) {
        controller = FakeMonitoringController(
          startResult: Completer<void>().future,
          onTrigger: onTrigger,
          onError: onError,
          events: [],
        );
        return controller;
      },
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Sensor belum siap'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(controller.disposeCount, 1);
  });

  testWidgets('retry disposes the old sensor before starting a new one',
      (tester) async {
    final events = <String>[];
    final controllers = <FakeMonitoringController>[];
    var attempt = 0;
    await tester.pumpWidget(_subject(
      permissions: FakePermissionService(() async => _granted),
      factory: ({required onTrigger, required onError}) {
        attempt++;
        final controller = FakeMonitoringController(
          startResult:
              attempt == 1 ? Completer<void>().future : Future<void>.value(),
          onTrigger: onTrigger,
          onError: onError,
          events: events,
        );
        controllers.add(controller);
        return controller;
      },
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    await tester.pump();
    await tester.tap(find.text('Coba lagi'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(controllers, hasLength(2));
    expect(controllers.first.disposeCount, 1);
    expect(events, ['start', 'dispose', 'start']);
    expect(find.text('Sensor Aktif'), findsOneWidget);
  });

  testWidgets(
      'denied notification permission shows a notice but monitoring still starts',
      (tester) async {
    await tester.pumpWidget(_subject(
      permissions: FakePermissionService(
        () async => _granted,
        notification: const NotificationPermissionResult(
          status: PermissionStatus.denied,
        ),
      ),
      factory: ({required onTrigger, required onError}) =>
          FakeMonitoringController(
        startResult: Future<void>.value(),
        onTrigger: onTrigger,
        onError: onError,
        events: [],
      ),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Sensor Aktif'), findsOneWidget);
    expect(find.textContaining('Izin notifikasi belum diberikan'),
        findsOneWidget);
  });

  testWidgets(
      'monitoring still detects a new incident after returning from the previous one',
      (tester) async {
    await tester.pumpWidget(_subject(
      permissions: FakePermissionService(() async => _granted),
      factory: ({required onTrigger, required onError}) =>
          FakeMonitoringController(
        startResult: Future<void>.value(),
        onTrigger: onTrigger,
        onError: onError,
        events: [],
      ),
      routes: {
        '/incident': (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali dari insiden'),
                ),
              ),
            ),
      },
    ));
    await tester.pumpAndSettle();

    for (var round = 1; round <= 2; round++) {
      await tester.ensureVisible(find.text('Simulasikan Shake/Fall'));
      await tester.tap(find.text('Simulasikan Shake/Fall'));
      await tester.pumpAndSettle();
      expect(find.text('Kembali dari insiden'), findsOneWidget,
          reason: 'insiden ke-$round harus membuka layar insiden');
      await tester.tap(find.text('Kembali dari insiden'));
      await tester.pumpAndSettle();
    }
  });
}

MonitoringController _unusedFactory({
  required void Function(TriggerSource source) onTrigger,
  required MonitoringErrorCallback onError,
}) {
  throw StateError('Sensor factory should not be used in this test.');
}
