import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/validation/contact_validation.dart';

void main() {
  group('validateContactName', () {
    const blankNames = ['', ' ', '   ', '\t', ' \n '];

    for (final raw in blankNames) {
      test('menolak nama kosong atau spasi (panjang ${raw.length})', () {
        expect(validateContactName(raw), 'Nama wajib diisi');
      });
    }

    test('menerima nama yang berisi karakter, spasi di tepi diabaikan', () {
      expect(validateContactName(' Ani '), isNull);
      expect(validateContactName('A'), isNull);
    });
  });

  group('validateContactPhone', () {
    const tooShort = ['', ' ', '1', '12', '--', '+()', '1 2'];

    for (final raw in tooShort) {
      test('menolak "$raw" karena kurang dari 3 digit', () {
        expect(validateContactPhone(raw), 'Masukkan minimal 3 digit');
      });
    }

    const valid = [
      '911',
      '112',
      '08123456789',
      '+62 812-3456-789',
      '(021) 555.1234',
      '  911  ',
      '1 1 2',
    ];

    for (final raw in valid) {
      test('menerima "$raw"', () {
        expect(validateContactPhone(raw), isNull);
      });
    }

    test('menolak huruf walaupun jumlah digitnya cukup', () {
      const message = 'Gunakan angka dan simbol nomor telepon yang valid';
      expect(validateContactPhone('abc123'), message);
      expect(validateContactPhone('ab 123'), message);
      expect(validateContactPhone('0812#345'), message);
    });

    test('batas minimal digit adalah $minPhoneDigits', () {
      expect(validateContactPhone('12'), isNotNull);
      expect(validateContactPhone('123'), isNull);
    });
  });
}
