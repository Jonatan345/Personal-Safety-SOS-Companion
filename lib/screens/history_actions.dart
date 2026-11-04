import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/incident.dart';
import '../models/incident_status.dart';
import '../notifiers/incident_notifier.dart';
import '../theme/app_theme.dart';
import '../utils/error_messages.dart';
import '../utils/snackbars.dart';
import '../widgets/incident_detail_sheet.dart';

/// Tindakan di layar riwayat (konfirmasi, hapus + urungkan, detail). Dipisah
/// dari layar agar layar hanya menyusun tampilan.
Future<bool> confirmDeleteIncident(BuildContext context) async {
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

Future<void> deleteIncidentWithUndo(
  BuildContext context,
  WidgetRef ref,
  Incident item,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(incidentNotifierProvider.notifier);

  try {
    await notifier.deleteIncident(item.id);
  } catch (error) {
    _reportFailure(messenger, 'Insiden gagal dihapus.', error);
    return;
  }

  showMessage(
    messenger,
    'Insiden dihapus.',
    duration: const Duration(seconds: 6),
    replace: true,
    action: SnackBarAction(
      label: 'Urungkan',
      onPressed: () async {
        try {
          await notifier.addIncident(item);
        } catch (error) {
          _reportFailure(messenger, 'Gagal mengurungkan.', error);
        }
      },
    ),
  );
}

Future<void> showIncidentDetails(
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
    builder: (sheetContext) => IncidentDetailSheet(
      item: item,
      onChangeStatus: () async {
        Navigator.pop(sheetContext);
        final next = item.status == IncidentStatus.sent
            ? IncidentStatus.cancelled
            : IncidentStatus.sent;
        try {
          await notifier.updateStatus(item.id, next);
          showMessage(messenger, 'Status catatan diperbarui.');
        } catch (error) {
          _reportFailure(messenger, 'Status gagal diperbarui.', error);
        }
      },
      onDelete: () async {
        Navigator.pop(sheetContext);
        if (!context.mounted) return;
        final confirmed = await confirmDeleteIncident(context);
        if (confirmed && context.mounted) {
          await deleteIncidentWithUndo(context, ref, item);
        }
      },
    ),
  );
}

void _reportFailure(
  ScaffoldMessengerState messenger,
  String prefix,
  Object error,
) {
  showMessage(messenger, '$prefix ${userMessageFor(error)}');
}
