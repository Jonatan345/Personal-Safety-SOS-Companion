import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../models/incident_status.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_card.dart';
import 'status_badge.dart';

/// Satu baris riwayat insiden. Dibacakan sekali sebagai tombol.
class IncidentTile extends StatelessWidget {
  const IncidentTile({super.key, required this.item, required this.onTap});

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
