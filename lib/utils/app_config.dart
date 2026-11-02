/// Satu-satunya tempat angka ambang deteksi dan hitung mundur SOS.
/// Service dan teks UI membaca nilai yang sama dari sini.
abstract final class SosConfig {
  static const double accelerationThreshold = 25; // m/s²
  static const double soundThresholdDb = 85;
  static const Duration triggerCooldown = Duration(seconds: 12);
  static const int countdownSeconds = 10;
}
