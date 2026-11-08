import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_logger.dart';
import '../theme/app_theme.dart';
import '../utils/app_info.dart';
import '../utils/snackbars.dart';
import '../widgets/responsive_body.dart';
import '../widgets/state_views.dart';

/// Layar log aplikasi untuk menelusuri masalah saat aplikasi berjalan.
class LogScreen extends StatelessWidget {
  LogScreen({super.key, AppLogger? logger})
      : logger = logger ?? AppLogger.instance;

  final AppLogger logger;

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: logger.exportText()));
    showMessage(
      messenger,
      'Log disalin. Tempelkan ke pesan untuk dikirim ke pengembang.',
      replace: true,
    );
  }

  Future<void> _clear(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await logger.clear();
    showMessage(messenger, 'Log dihapus.', replace: true);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: logger.changes,
      builder: (context, _, __) {
        final entries = logger.entries.reversed.toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Log Aplikasi'),
            actions: [
              IconButton(
                tooltip: 'Salin log',
                icon: const Icon(Icons.copy_outlined),
                onPressed: entries.isEmpty ? null : () => _copy(context),
              ),
              IconButton(
                tooltip: 'Hapus log',
                icon: const Icon(Icons.delete_outline),
                onPressed: entries.isEmpty ? null : () => _clear(context),
              ),
            ],
          ),
          body: SafeArea(
            child: entries.isEmpty
                ? const StateMessageView(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum ada log',
                    message: 'Kejadian penting aplikasi akan tercatat di sini.',
                  )
                : ContentWidth(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: entries.length + 1,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Text(
                            'Versi ${AppInfo.label} · ${entries.length} entri',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          );
                        }
                        return _LogLine(entry: entries[index - 1]);
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.entry});

  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.level) {
      LogLevel.error => AppColors.danger,
      LogLevel.warning => const Color(0xFFB45309),
      LogLevel.info => AppColors.textPrimary,
    };
    return SelectableText(
      entry.format(),
      style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: color),
    );
  }
}
