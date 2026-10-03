import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/status_badge.dart';
import '../models/incident.dart';
import '../notifiers/incident_notifier.dart';

/// LOCAL DATA & PERSISTENCE (P5) — UI LAYER
/// Reads/writes through incidentNotifierProvider (Riverpod -> Repository -> Hive box).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _addDummyIncident(WidgetRef ref) async {
    final incident = Incident(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      latitude: -6.2088,
      longitude: 106.8456,
      status: 'sent',
    );
    await ref.read(incidentNotifierProvider.notifier).addIncident(incident);
  }

  Future<void> _toggleStatus(WidgetRef ref, Incident item) async {
    final newStatus = item.status == 'sent' ? 'cancelled' : 'sent';
    await ref.read(incidentNotifierProvider.notifier).updateStatus(item.id, newStatus);
  }

  Future<void> _deleteIncident(WidgetRef ref, Incident item) async {
    await ref.read(incidentNotifierProvider.notifier).deleteIncident(item.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(incidentNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Insiden'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _addDummyIncident(ref),
          ),
        ],
      ),
      body: SafeArea(
        child: data.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: data.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final item = data[i];
                  final sent = item.status == 'sent';
                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _deleteIncident(ref, item),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    child: GestureDetector(
                      onTap: () => _toggleStatus(ref, item),
                      child: AppCard(
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: (sent ? AppColors.danger : AppColors.textSecondary)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                sent ? Icons.warning_amber_rounded : Icons.cancel_outlined,
                                color: sent ? AppColors.danger : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year} • '
                                    '${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              label: sent ? 'Terkirim' : 'Dibatalkan',
                              color: sent ? AppColors.danger : AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
          Icon(Icons.inbox_outlined, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text('Belum ada riwayat insiden', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('Tap + di atas untuk tambah data uji',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
