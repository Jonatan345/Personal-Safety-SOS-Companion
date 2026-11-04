import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/models/incident_status.dart';
import 'package:sos_companion/utils/formatters.dart';

void main() {
  test('tanggal dan jam selalu diberi nol di depan', () {
    final time = DateTime(2026, 1, 5, 7, 3);

    expect(formatDate(time), '05/01/2026');
    expect(formatClock(time), '07:03');
    expect(formatDateTime(time), '05/01/2026 • 07:03');
  });

  test('versi untuk pembaca layar tidak memakai simbol titik', () {
    expect(
      formatDateTimeSpoken(DateTime(2026, 10, 15, 5)),
      '15/10/2026 pukul 05:00',
    );
  });

  test('label status memakai Bahasa Indonesia', () {
    expect(IncidentStatus.label(IncidentStatus.sent), 'Terkirim');
    expect(IncidentStatus.label(IncidentStatus.cancelled), 'Dibatalkan');
    expect(IncidentStatus.label(IncidentStatus.pending), 'Menunggu');
  });
}
