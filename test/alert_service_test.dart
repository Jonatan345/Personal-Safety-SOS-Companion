import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/services/alert_service.dart';

void main() {
  group('AlertService.createSmsUri (Bug #5)', () {
    test('encodes spaces as %20 instead of + in query body', () {
      const phone = '081234567890';
      const message =
          'SOS: kemungkinan insiden terdeteksi. Lokasi saya: https://maps.google.com/?q=-6.2088,106.8456';

      final uri = AlertService.createSmsUri(phone: phone, message: message);

      expect(uri.scheme, 'sms');
      expect(uri.path, phone);
      // Ensure %20 is used and no '+' is used as space replacement
      expect(uri.query, contains('%20'));
      expect(uri.query, isNot(contains('+')));
      expect(uri.toString(), startsWith('sms:081234567890?body='));
      expect(uri.toString(), contains('%20'));
      expect(uri.toString(), isNot(contains('+')));
      // Decoding the body gives the exact original message
      expect(Uri.decodeComponent(uri.query.replaceFirst('body=', '')), message);
    });

    test('properly handles special characters, accents and punctuation', () {
      const phone = '08123456789';
      const message = 'Darurat! Tolong saya — segera';

      final uri = AlertService.createSmsUri(phone: phone, message: message);

      expect(uri.path, phone);
      expect(uri.query, isNot(contains('+')));
      expect(Uri.decodeComponent(uri.query.replaceFirst('body=', '')), message);
    });

    test('supports multiple recipients separated by comma (Feature #11)', () {
      const phones = '081234567890,081234567891';
      const message = 'SOS Darurat';
      final uri = AlertService.createSmsUri(phone: phones, message: message);
      expect(uri.path, phones);
      expect(uri.toString(), startsWith('sms:081234567890,081234567891?body='));
    });
  });
}
