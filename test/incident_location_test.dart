import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sos_companion/models/incident.dart';
import 'package:sos_companion/services/permission_service.dart';
import 'package:sos_companion/utils/sos_message.dart';

const _json = {
  'id': 'incident-1',
  'timestamp': '2026-10-15T05:00:00.000Z',
  'latitude': null,
  'longitude': null,
  'status': 'sent',
};

void main() {
  group('lokasi insiden', () {
    test('menerima lokasi null dan tidak mengubahnya menjadi 0,0', () {
      final incident = Incident.fromJson(_json);
      expect(incident.latitude, isNull);
      expect(incident.longitude, isNull);
      expect(incident.hasLocation, isFalse);
      expect(incident.toJson(), _json);
    });

    test('menolak jika hanya salah satu koordinat yang null', () {
      expect(
        () => Incident.fromJson({..._json, 'latitude': -6.2}),
        throwsFormatException,
      );
    });

    test('data lama 0,0 dianggap tidak punya lokasi', () {
      final legacy = Incident.fromJson(
        {..._json, 'latitude': 0, 'longitude': 0},
      );
      expect(legacy.hasLocation, isFalse);
      expect(legacy.locationLabel, 'Lokasi tidak tersedia');
    });

    test('insiden dibatalkan diberi label berbeda', () {
      final cancelled = Incident.fromJson({..._json, 'status': 'cancelled'});
      expect(cancelled.locationLabel, 'Lokasi tidak diambil (dibatalkan)');
    });
  });

  group('pesan SOS', () {
    test('menyertakan tautan peta saat lokasi ada', () {
      expect(
        buildSosMessage(latitude: -6.2088, longitude: 106.8456),
        contains('https://maps.google.com/?q=-6.2088,106.8456'),
      );
    });

    test('tidak membuat tautan palsu saat lokasi null', () {
      final message = buildSosMessage();
      expect(message, isNot(contains('maps.google.com')));
      expect(message, isNot(contains('0.0')));
      expect(message, contains('tidak tersedia'));
    });
  });

  group('izin notifikasi', () {
    test('granted tidak menampilkan pesan', () {
      const result =
          NotificationPermissionResult(status: PermissionStatus.granted);
      expect(result.granted, isTrue);
      expect(result.message, isNull);
    });

    test('denied menampilkan pesan, permanentlyDenied menawarkan Pengaturan',
        () {
      const denied =
          NotificationPermissionResult(status: PermissionStatus.denied);
      const blocked = NotificationPermissionResult(
          status: PermissionStatus.permanentlyDenied);
      expect(denied.message, isNotNull);
      expect(denied.needsSettings, isFalse);
      expect(blocked.message, contains('diblokir'));
      expect(blocked.needsSettings, isTrue);
    });
  });
}
