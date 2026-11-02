/// Nilai status insiden. Dipakai bersama oleh model, layar, dan notifier
/// agar tidak ada string literal yang tersebar.
abstract final class IncidentStatus {
  static const sent = 'sent';
  static const cancelled = 'cancelled';
  static const pending = 'pending';
  static const all = {sent, cancelled, pending};

  static String label(String status) {
    if (status == sent) return 'Terkirim';
    if (status == cancelled) return 'Dibatalkan';
    return 'Menunggu';
  }
}
