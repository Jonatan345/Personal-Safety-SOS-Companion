import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../utils/app_info.dart';
import '../utils/formatters.dart';
import 'local_storage_service.dart';

enum LogLevel {
  info('INFO'),
  warning('WARN'),
  error('ERROR');

  const LogLevel(this.label);
  final String label;
}

class LogEntry {
  const LogEntry({
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    final time = DateTime.tryParse('${json['time']}');
    final level = LogLevel.values.where((item) => item.name == json['level']);
    if (time == null || level.isEmpty) {
      throw const FormatException('Log entry is invalid.');
    }
    return LogEntry(
      time: time,
      level: level.first,
      tag: '${json['tag']}',
      message: '${json['message']}',
    );
  }

  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;

  String format() {
    final second = time.toLocal().second.toString().padLeft(2, '0');
    return '${formatDate(time)} ${formatClock(time)}:$second '
        '[${level.label}] $tag: $message';
  }

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'level': level.name,
        'tag': tag,
        'message': message,
      };
}

/// Log aplikasi untuk menelusuri masalah saat aplikasi berjalan (termasuk
/// build rilis). Entri disimpan di memori dan, setelah [enablePersistence],
/// juga di Hive sehingga tetap ada setelah aplikasi ditutup. Mencatat log
/// tidak pernah melempar error.
class AppLogger {
  AppLogger({this.maxEntries = 300});

  static final AppLogger instance = AppLogger();

  final int maxEntries;
  final List<LogEntry> _entries = [];

  /// Bertambah setiap ada perubahan; dipakai layar log untuk membangun ulang.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);
  Box<String>? _box;

  List<LogEntry> get entries => List.unmodifiable(_entries);

  void info(String tag, String message) =>
      _add(LogLevel.info, tag, message, null, null);

  void warning(String tag, String message, [Object? error]) =>
      _add(LogLevel.warning, tag, message, error, null);

  void error(String tag, String message, [Object? error, StackTrace? stack]) =>
      _add(LogLevel.error, tag, message, error, stack);

  void _add(
    LogLevel level,
    String tag,
    String message,
    Object? error,
    StackTrace? stack,
  ) {
    final details = StringBuffer(message);
    if (error != null) details.write(' | $error');
    if (stack != null) {
      final lines = stack.toString().trim().split('\n').take(4);
      details.write('\n${lines.join('\n')}');
    }
    final entry = LogEntry(
      time: DateTime.now(),
      level: level,
      tag: tag,
      message: details.toString(),
    );

    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
    debugPrint(entry.format());
    changes.value++;
    unawaited(_persist(entry));
  }

  /// Memuat log sesi sebelumnya dan mulai menyimpan entri baru ke Hive.
  Future<void> enablePersistence() async {
    try {
      await LocalStorageService.ensureReady();
      final box = Hive.box<String>(LocalStorageService.logsBox);
      final previous = <LogEntry>[];
      for (final value in box.values) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map<String, dynamic>) {
            previous.add(LogEntry.fromJson(decoded));
          }
        } on FormatException {
          // Entri log rusak diabaikan.
        }
      }
      _entries.insertAll(0, previous);
      if (_entries.length > maxEntries) {
        _entries.removeRange(0, _entries.length - maxEntries);
      }
      _box = box;
      changes.value++;
    } catch (error) {
      debugPrint('Log tidak dapat disimpan permanen: $error');
    }
  }

  Future<void> _persist(LogEntry entry) async {
    final box = _box;
    if (box == null) return;
    try {
      await box.add(jsonEncode(entry.toJson()));
      final excess = box.length - maxEntries;
      if (excess > 0) {
        await box.deleteAll(box.keys.take(excess).toList());
      }
    } catch (_) {
      // Gagal menyimpan log tidak boleh mengganggu aplikasi.
    }
  }

  Future<void> clear() async {
    _entries.clear();
    changes.value++;
    try {
      await _box?.clear();
    } catch (_) {
      // Abaikan.
    }
  }

  /// Teks lengkap untuk disalin dan dikirim ke pengembang.
  String exportText() {
    final header = 'SOS Companion ${AppInfo.label}\n'
        'Diekspor: ${formatDateTime(DateTime.now())}\n'
        'Jumlah entri: ${_entries.length}\n';
    return '$header\n${_entries.map((entry) => entry.format()).join('\n')}';
  }
}
