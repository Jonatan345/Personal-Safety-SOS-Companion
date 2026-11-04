import 'package:flutter/material.dart';

import '../notifiers/incident_notifier.dart';
import '../theme/app_theme.dart';

/// Status sinkronisasi dengan backend di atas daftar riwayat.
class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key, required this.state, required this.onRetry});

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
