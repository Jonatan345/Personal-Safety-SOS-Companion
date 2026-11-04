import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../models/incident_status.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Isi bottom sheet detail insiden dengan tindakan eksplisit.
class IncidentDetailSheet extends StatelessWidget {
  const IncidentDetailSheet({
    super.key,
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
