import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/status_badge.dart';
import '../notifiers/incident_notifier.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perubahan gagal disimpan: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(incidentNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Insiden')),
      body: SafeArea(
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            error: error,
            onRetry: () =>
                ref.read(incidentNotifierProvider.notifier).refresh(),
          ),
          data: (incidents) => incidents.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(incidentNotifierProvider.notifier).refresh(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: incidents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final item = incidents[i];
                          final sent = item.status == 'sent';
                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _runAction(
                              context,
                              () => ref
                                  .read(incidentNotifierProvider.notifier)
                                  .deleteIncident(item.id),
                              'Insiden berhasil dihapus.',
                            ),
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
                            child: Semantics(
                              button: true,
                              label:
                                  'Insiden ${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year}, status ${sent ? 'terkirim' : 'dibatalkan'}',
                              hint: 'Ketuk untuk mengubah status insiden',
                              child: GestureDetector(
                                onTap: () => _runAction(
                                  context,
                                  () => ref
                                      .read(incidentNotifierProvider.notifier)
                                      .updateStatus(
                                        item.id,
                                        sent ? 'cancelled' : 'sent',
                                      ),
                                  'Status insiden berhasil diperbarui.',
                                ),
                                child: AppCard(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: (sent
                                                  ? AppColors.danger
                                                  : AppColors.textSecondary)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          sent
                                              ? Icons.warning_amber_rounded
                                              : Icons.cancel_outlined,
                                          color: sent
                                              ? AppColors.danger
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year} • '
                                              '${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600),
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
                                      StatusBadge(
                                        label: sent ? 'Terkirim' : 'Dibatalkan',
                                        color: sent
                                            ? AppColors.danger
                                            : AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Riwayat gagal dimuat dari server.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 56, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text('Belum ada riwayat insiden',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('Insiden yang tercatat akan muncul di sini',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
