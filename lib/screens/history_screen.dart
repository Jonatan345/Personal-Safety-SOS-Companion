import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/incident.dart';
import '../models/incident_status.dart';
import '../notifiers/incident_notifier.dart';
import '../theme/app_theme.dart';
import '../utils/error_messages.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/responsive_body.dart';
import '../widgets/state_views.dart';
import '../widgets/status_badge.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(incidentNotifierProvider);
    final notifier = ref.read(incidentNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Insiden')),
      body: SafeArea(
        child: data.when(
          loading: () => const LoadingView(label: 'Memuat riwayat insiden…'),
          error: (error, _) => StateMessageView(
            icon: Icons.error_outline,
            iconColor: AppColors.danger,
            title: 'Riwayat gagal dimuat dari perangkat.',
            message: userMessageFor(error),
            announce: true,
            action: FilledButton.icon(
              onPressed: notifier.refresh,
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ),
          data: (incidents) => _HistoryList(incidents: incidents),
        ),
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.incidents});

  final List<Incident> incidents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(incidentSyncProvider);
    final notifier = ref.read(incidentNotifierProvider.notifier);

    return Column(
      children: [
        _SyncBanner(state: sync, onRetry: notifier.refresh),
        Expanded(
          child: incidents.isEmpty
              ? const StateMessageView(
                  icon: Icons.inbox_outlined,
                  title: 'Belum ada riwayat insiden',
                  message: 'Insiden yang tercatat akan muncul di sini.',
                )
              : RefreshIndicator(
                  onRefresh: notifier.refresh,
                  child: ContentWidth(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: incidents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = incidents[index];
                        return Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            if (!await _confirmDelete(context)) return false;
                            if (context.mounted) {
                              await _deleteWithUndo(context, ref, item);
                            }
                            // Item hilang lewat state notifier, bukan lewat
                            // animasi Dismissible.
                            return false;
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.white),
                          ),
                          child: _IncidentTile(
                            item: item,
                            onTap: () => _showDetails(context, ref, item),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.state, required this.onRetry});

  final IncidentSyncState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    switch (state.phase) {
      case IncidentSyncPhase.idle:
        return const SizedBox.shrink();
      case IncidentSyncPhase.syncing:
        return Semantics(
          liveRegion: true,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  'Menyinkronkan dengan server…',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      case IncidentSyncPhase.failed:
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_outlined,
                      color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${state.message} Menampilkan riwayat dari perangkat.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}

class _IncidentTile extends StatelessWidget {
  const _IncidentTile({required this.item, required this.onTap});

  final Incident item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sent = item.status == IncidentStatus.sent;
    final color = sent ? AppColors.danger : AppColors.textSecondary;
    final statusLabel = IncidentStatus.label(item.status);

    return AppCard(
      onTap: onTap,
      semanticLabel: 'Insiden ${formatDateTimeSpoken(item.timestamp)}, '
          'status ${statusLabel.toLowerCase()}, ${item.locationLabel}',
      semanticHint: 'Ketuk untuk melihat detail dan tindakan',
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              sent ? Icons.warning_amber_rounded : Icons.cancel_outlined,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDateTime(item.timestamp),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  item.locationLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(label: statusLabel, color: color),
        ],
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus insiden ini?'),
      content: const Text(
        'Catatan akan dihapus dari riwayat. Anda masih bisa mengurungkannya '
        'sesaat setelah dihapus.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<void> _deleteWithUndo(
  BuildContext context,
  WidgetRef ref,
  Incident item,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(incidentNotifierProvider.notifier);
  try {
    await notifier.deleteIncident(item.id);
  } catch (error) {
    messenger.showSnackBar(SnackBar(
      content: Text('Insiden gagal dihapus. ${userMessageFor(error)}'),
    ));
    return;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: const Text('Insiden dihapus.'),
      duration: const Duration(seconds: 6),
      action: SnackBarAction(
        label: 'Urungkan',
        onPressed: () async {
          try {
            await notifier.addIncident(item);
          } catch (error) {
            messenger.showSnackBar(SnackBar(
              content:
                  Text('Gagal mengurungkan. ${userMessageFor(error)}'),
            ));
          }
        },
      ),
    ));
}

Future<void> _showDetails(
  BuildContext context,
  WidgetRef ref,
  Incident item,
) {
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(incidentNotifierProvider.notifier);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _DetailSheet(
      item: item,
      onChangeStatus: () async {
        Navigator.pop(sheetContext);
        final next = item.status == IncidentStatus.sent
            ? IncidentStatus.cancelled
            : IncidentStatus.sent;
        try {
          await notifier.updateStatus(item.id, next);
          messenger.showSnackBar(
            const SnackBar(content: Text('Status catatan diperbarui.')),
          );
        } catch (error) {
          messenger.showSnackBar(SnackBar(
            content: Text('Status gagal diperbarui. ${userMessageFor(error)}'),
          ));
        }
      },
      onDelete: () async {
        Navigator.pop(sheetContext);
        if (!context.mounted) return;
        final confirmed = await _confirmDelete(context);
        if (confirmed && context.mounted) {
          await _deleteWithUndo(context, ref, item);
        }
      },
    ),
  );
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.item,
    required this.onChangeStatus,
    required this.onDelete,
  });

  final Incident item;
  final VoidCallback onChangeStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final sent = item.status == IncidentStatus.sent;
    final nextLabel = IncidentStatus.label(
      sent ? IncidentStatus.cancelled : IncidentStatus.sent,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detail Insiden',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _DetailRow(label: 'Waktu', value: formatDateTime(item.timestamp)),
            _DetailRow(label: 'Lokasi', value: item.locationLabel),
            _DetailRow(
                label: 'Status', value: IncidentStatus.label(item.status)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onChangeStatus,
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.edit_outlined),
              label: Text('Ubah catatan menjadi "$nextLabel"'),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hanya mengubah catatan riwayat, bukan pengiriman SMS.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onDelete,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.danger,
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus insiden'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
