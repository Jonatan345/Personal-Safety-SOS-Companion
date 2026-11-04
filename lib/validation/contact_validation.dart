/// Aturan input kontak darurat sebagai fungsi murni (tanpa widget dan tanpa
/// jaringan). Nilai `null` berarti input valid.
const int minPhoneDigits = 3;

final RegExp _nonDigit = RegExp(r'[^0-9]');
final RegExp _allowedPhoneCharacters = RegExp(r'^[0-9+()\-\s.]+$');

String? validateContactName(String raw) {
  return raw.trim().isEmpty ? 'Nama wajib diisi' : null;
}

String? validateContactPhone(String raw) {
  final phone = raw.trim();
  final digitCount = phone.replaceAll(_nonDigit, '').length;

  if (digitCount < minPhoneDigits) {
    return 'Masukkan minimal $minPhoneDigits digit';
  }
  if (!_allowedPhoneCharacters.hasMatch(phone)) {
    return 'Gunakan angka dan simbol nomor telepon yang valid';
  }
  return null;
}
