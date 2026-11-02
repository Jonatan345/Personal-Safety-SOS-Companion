import 'dart:async';

import '../services/incident_api.dart';

/// Pesan kesalahan untuk pengguna: selalu Bahasa Indonesia dan tidak pernah
/// menampilkan teks exception mentah.
String userMessageFor(Object error) {
  if (error is IncidentApiException) return error.userMessage;
  if (error is TimeoutException) {
    return 'Permintaan melewati batas waktu. Coba lagi.';
  }
  if (error is FormatException) return 'Data tidak valid atau rusak.';
  return 'Terjadi kesalahan. Coba lagi.';
}
