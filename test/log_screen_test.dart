import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_companion/screens/log_screen.dart';
import 'package:sos_companion/services/app_logger.dart';
import 'package:sos_companion/utils/app_info.dart';

Widget _subject(AppLogger logger) =>
    MaterialApp(home: LogScreen(logger: logger));

void main() {
  testWidgets('shows an empty state when nothing was logged', (tester) async {
    await tester.pumpWidget(_subject(AppLogger()));

    expect(find.text('Belum ada log'), findsOneWidget);
  });

  testWidgets('lists entries newest first with the app version',
      (tester) async {
    final logger = AppLogger()
      ..info('app', 'entri lama')
      ..error('incident', 'entri baru');
    await tester.pumpWidget(_subject(logger));

    expect(find.textContaining('Versi ${AppInfo.label} · 2 entri'),
        findsOneWidget);
    final newest = tester.getTopLeft(find.textContaining('entri baru'));
    final oldest = tester.getTopLeft(find.textContaining('entri lama'));
    expect(newest.dy, lessThan(oldest.dy));
  });

  testWidgets('a new entry appears without reopening the screen',
      (tester) async {
    final logger = AppLogger()..info('app', 'awal');
    await tester.pumpWidget(_subject(logger));

    logger.warning('sync', 'muncul belakangan');
    await tester.pump();

    expect(find.textContaining('muncul belakangan'), findsOneWidget);
  });

  testWidgets('copy puts the full log on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final logger = AppLogger()..error('incident', 'gagal simpan');
    await tester.pumpWidget(_subject(logger));

    await tester.tap(find.byTooltip('Salin log'));
    await tester.pumpAndSettle();

    expect(copied, contains('gagal simpan'));
    expect(copied, contains('SOS Companion ${AppInfo.label}'));
    expect(find.textContaining('Log disalin'), findsOneWidget);
  });

  testWidgets('clear empties the list and says so', (tester) async {
    final logger = AppLogger()..info('app', 'mulai');
    await tester.pumpWidget(_subject(logger));

    await tester.tap(find.byTooltip('Hapus log'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada log'), findsOneWidget);
    expect(find.text('Log dihapus.'), findsOneWidget);
  });
}
