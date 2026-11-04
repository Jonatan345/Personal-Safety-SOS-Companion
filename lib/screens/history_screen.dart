import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/incident.dart';
import '../notifiers/incident_notifier.dart';
import '../theme/app_theme.dart';
import '../utils/error_messages.dart';
import '../widgets/incident_tile.dart';
import '../widgets/responsive_body.dart';
import '../widgets/state_views.dart';
import '../widgets/sync_banner.dart';
import 'history_actions.dart';

/// Layar riwayat insiden: loading, kosong, error, dan daftar. Tindakan ada di
/// `history_actions.dart`.
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
        SyncBanner(state: sync, onRetry: notifier.refresh),
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
                      itemBuilder: (context, index) =>
                          _buildItem(context, ref, incidents[index]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, WidgetRef ref, Incident item) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        if (!await confirmDeleteIncident(context)) return false;
        if (context.mounted) await deleteIncidentWithUndo(context, ref, item);
        // Item hilang lewat state notifier, bukan lewat animasi Dismissible.
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: IncidentTile(
        item: item,
        onTap: () => showIncidentDetails(context, ref, item),
      ),
    );
  }
}
