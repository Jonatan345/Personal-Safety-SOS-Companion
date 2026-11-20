import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/services/app_logger.dart';
import 'package:sos_companion/utils/app_info.dart';

void main() {
  test('records entries with level, tag and message', () {
    final logger = AppLogger()
      ..info('app', 'mulai')
      ..warning('sync', 'server lambat')
      ..error('incident', 'gagal simpan', StateError('disk penuh'));

    expect(logger.entries.map((entry) => entry.level), [
      LogLevel.info,
      LogLevel.warning,
      LogLevel.error,
    ]);
    expect(logger.entries.last.message, contains('gagal simpan'));
    expect(logger.entries.last.message, contains('[status: StateError]'));
    expect(logger.entries.last.message, isNot(contains('disk penuh')));
  });

  test('does not record incident JSON or location from an exception', () {
    final logger = AppLogger();
    const privatePayload =
        '{"latitude":-6.2088,"longitude":106.8456,"timestamp":"2026"}';

    logger.warning(
      'data',
      'Melewati catatan insiden rusak',
      const FormatException(privatePayload),
    );

    final message = logger.entries.single.message;
    expect(message, 'Melewati catatan insiden rusak [status: FormatException]');
    expect(message, isNot(contains('latitude')));
    expect(message, isNot(contains('longitude')));
    expect(logger.exportText(), isNot(contains(privatePayload)));
  });

  test('keeps only the newest entries when the limit is reached', () {
    final logger = AppLogger(maxEntries: 3);
    for (var i = 1; i <= 5; i++) {
      logger.info('app', 'entri $i');
    }

    expect(
      logger.entries.map((entry) => entry.message),
      ['entri 3', 'entri 4', 'entri 5'],
    );
  });

  test('formats a line with time, level and tag', () {
    final entry = LogEntry(
      time: DateTime(2026, 1, 5, 7, 3, 9),
      level: LogLevel.warning,
      tag: 'sync',
      message: 'server lambat',
    );

    expect(entry.format(), '05/01/2026 07:03:09 [WARN] sync: server lambat');
  });

  test('an entry survives a JSON round-trip and rejects broken data', () {
    final entry = LogEntry(
      time: DateTime(2026, 1, 5, 7, 3, 9),
      level: LogLevel.error,
      tag: 'app',
      message: 'gagal',
    );

    final restored = LogEntry.fromJson(entry.toJson());

    expect(restored.format(), entry.format());
    expect(
      () => LogEntry.fromJson({'time': 'x', 'level': 'info'}),
      throwsFormatException,
    );
  });

  test('exports text with the app version and every entry', () {
    final logger = AppLogger()
      ..info('app', 'mulai')
      ..error('incident', 'gagal');

    final text = logger.exportText();

    expect(text, contains('SOS Companion ${AppInfo.label}'));
    expect(text, contains('Jumlah entri: 2'));
    expect(text, contains('[INFO] app: mulai'));
    expect(text, contains('[ERROR] incident: gagal'));
  });

  test('clear removes all entries and notifies listeners', () async {
    final logger = AppLogger()..info('app', 'mulai');
    var notified = 0;
    logger.changes.addListener(() => notified++);

    await logger.clear();

    expect(logger.entries, isEmpty);
    expect(notified, 1);
  });
}
