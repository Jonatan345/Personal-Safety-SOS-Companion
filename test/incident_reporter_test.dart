import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/models/emergency_contact.dart';
import 'package:sos_companion/models/incident.dart';
import 'package:sos_companion/services/location_service.dart';
import 'package:sos_companion/use_cases/incident_reporter.dart';

import 'support/fakes.dart';

final _startTime = DateTime.utc(2026, 10, 15, 5);

class _Harness {
  _Harness({
    this.locate,
    this.saveFails = false,
    this.contact = testContact,
    this.contactFails = false,
    FakeAlerts? alerts,
    DateTime Function()? clock,
  })  : alerts = alerts ?? FakeAlerts(),
        _clock = clock ?? (() => _startTime);

  final Future<IncidentLocation> Function()? locate;
  final bool saveFails;
  final EmergencyContact? contact;
  final bool contactFails;
  final FakeAlerts alerts;
  final DateTime Function() _clock;
  final saved = <Incident>[];
  int locateCalls = 0;
  int contactLoads = 0;

  IncidentReporter get reporter => IncidentReporter(
        locate: () {
          locateCalls++;
          return (locate ?? _jakarta)();
        },
        save: (incident) async {
          if (saveFails) throw StateError('disk penuh');
          saved.add(incident);
        },
        loadContact: () async {
          contactLoads++;
          if (contactFails) throw StateError('gagal membaca');
          return contact;
        },
        alerts: alerts,
        clock: _clock,
      );
}

Future<IncidentLocation> _jakarta() async =>
    const IncidentLocation(-6.2088, 106.8456);

Future<IncidentLocation> _gpsOff() async =>
    throw StateError('Layanan lokasi perangkat sedang nonaktif.');

void main() {
  group('report', () {
    test('sent with GPS stores the location and prepares the SMS', () async {
      final harness = _Harness();

      final report = await harness.reporter.report('sent');

      expect(report.isSent, isTrue);
      expect(report.incident.latitude, -6.2088);
      expect(report.incident.longitude, 106.8456);
      expect(report.message,
          contains('https://maps.google.com/?q=-6.2088,106.8456'));
      expect(report.contact, testContact);
      expect(report.notes, isEmpty);
      expect(harness.saved.single, report.incident);
    });

    test('cancelled never asks for location or contact', () async {
      final harness = _Harness(locate: _gpsOff);

      final report = await harness.reporter.report('cancelled');

      expect(report.isSent, isFalse);
      expect(report.incident.status, 'cancelled');
      expect(report.incident.hasLocation, isFalse);
      expect(report.message, isEmpty);
      expect(report.notes, isEmpty);
      expect(harness.locateCalls, 0);
      expect(harness.contactLoads, 0);
      expect(harness.saved.single.status, 'cancelled');
    });

    test('GPS failure stores null (not 0,0) and explains why', () async {
      final harness = _Harness(locate: _gpsOff);

      final report = await harness.reporter.report('sent');

      expect(report.incident.latitude, isNull);
      expect(report.incident.longitude, isNull);
      expect(report.message, isNot(contains('maps.google.com')));
      expect(report.message, contains('tidak tersedia'));
      expect(
        report.notes,
        ['Layanan lokasi perangkat sedang nonaktif. '
            'Alert tetap dikirim tanpa lokasi.'],
      );
    });

    test('the incident time is taken before waiting for the GPS', () async {
      var now = _startTime;
      final harness = _Harness(
        clock: () => now,
        locate: () async {
          now = now.add(const Duration(seconds: 15));
          return const IncidentLocation(-6.2, 106.8);
        },
      );

      final report = await harness.reporter.report('sent');

      expect(report.incident.timestamp, _startTime);
    });

    test('a storage failure does not stop the alert', () async {
      final harness = _Harness(saveFails: true);

      final report = await harness.reporter.report('sent');

      expect(report.isSent, isTrue);
      expect(report.contact, testContact);
      expect(report.notes, ['Riwayat insiden gagal disimpan.']);
    });

    test('a cancelled incident still reports a storage failure', () async {
      final harness = _Harness(saveFails: true);

      final report = await harness.reporter.report('cancelled');

      expect(report.notes, ['Riwayat insiden gagal disimpan.']);
    });

    test('no emergency contact is reported', () async {
      final harness = _Harness(contact: null);

      final report = await harness.reporter.report('sent');

      expect(report.contact, isNull);
      expect(report.notes,
          ['Kontak darurat belum diatur, SMS tidak disiapkan.']);
    });

    test('a contact that cannot be loaded gets its own message', () async {
      final harness = _Harness(contactFails: true);

      final report = await harness.reporter.report('sent');

      expect(report.notes, ['Kontak darurat tidak dapat dimuat.']);
    });
  });

  group('dispatch', () {
    test('notifies then opens the SMS composer without extra notes', () async {
      final harness = _Harness();
      final report = await harness.reporter.report('sent');
      final batches = <List<String>>[];

      await harness.reporter.dispatch(report, batches.add);

      expect(harness.alerts.events, ['notification', 'sms']);
      expect(harness.alerts.smsPhones.single, '081234567890');
      expect(harness.alerts.smsMessages.single, report.message);
      expect(batches, isEmpty);
    });

    test('reports a notification failure before the SMS is opened', () async {
      final alerts = FakeAlerts(
        notificationFailure: 'Izin notifikasi belum diberikan.',
      );
      final harness = _Harness(alerts: alerts);
      final report = await harness.reporter.report('sent');

      await harness.reporter.dispatch(
        report,
        (notes) => alerts.events.add('notes:${notes.join('|')}'),
      );

      expect(alerts.events, [
        'notification',
        'notes:Izin notifikasi belum diberikan.',
        'sms',
      ]);
    });

    test('reports an SMS failure in a second batch', () async {
      final alerts = FakeAlerts(smsFailure: 'Aplikasi SMS tidak dapat dibuka.');
      final harness = _Harness(alerts: alerts);
      final report = await harness.reporter.report('sent');
      final batches = <List<String>>[];

      await harness.reporter.dispatch(report, batches.add);

      expect(batches, [
        ['Aplikasi SMS tidak dapat dibuka.'],
      ]);
    });

    test('without a contact it only notifies and never opens the SMS app',
        () async {
      final harness = _Harness(contact: null);
      final report = await harness.reporter.report('sent');
      final batches = <List<String>>[];

      await harness.reporter.dispatch(report, batches.add);

      expect(harness.alerts.events, ['notification']);
      expect(harness.alerts.notifications.single, contains('Atur kontak'));
      expect(batches.single,
          ['Kontak darurat belum diatur, SMS tidak disiapkan.']);
    });
  });
}
