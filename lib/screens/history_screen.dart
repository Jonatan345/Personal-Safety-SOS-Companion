import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/status_badge.dart';
import '../models/incident.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  List<Incident> get _dummyData => [
        Incident(
          id: '1',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          latitude: -6.2088,
          longitude: 106.8456,
          status: IncidentStatus.sent,
        ),
        Incident(
          id: '2',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          latitude: -6.9175,
          longitude: 107.6191,
          status: IncidentStatus.cancelled,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final data = _dummyData;
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Insiden')),
      body: SafeArea(
        child: data.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: data.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final item = data[i];
                  final sent = item.status == IncidentStatus.sent;
                  return AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (sent ? AppColors.danger : AppColors.textSecondary).withValues(alpha: 0.1),
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
        ],
      ),
    );
  }
}
