import 'package:flutter/material.dart';

import '../models/emergency_contact.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'primary_button.dart';
import 'state_views.dart';
/// Pratinjau langsung nama dan nomor yang sedang diketik.
class ContactSummaryCard extends StatelessWidget {
  const ContactSummaryCard({
    super.key,
    required this.name,
    required this.phoneNumber,
  });

  final String name;
  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const Key('contact-summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.primary, size: 32),
          const SizedBox(height: 12),
          Text(
            name.trim().isEmpty ? 'Kontak darurat' : name.trim(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            phoneNumber.trim().isEmpty
                ? 'Nomor telepon akan tampil di sini'
                : phoneNumber.trim(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kontak ini akan menerima pemberitahuan saat SOS dikirim.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Pastikan nama dan nomor telepon sudah benar sebelum menyimpan.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class EmptyContactCard extends StatelessWidget {
  const EmptyContactCard({super.key, required this.onAddContact});

  final VoidCallback onAddContact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const Key('contact-empty-state'),
      child: StateMessageView(
        icon: Icons.contact_phone_outlined,
        title: 'Belum ada kontak darurat',
        message: 'Tambahkan satu kontak yang akan menerima alert darurat Anda.',
        action: PrimaryButton(
          label: 'Tambah Kontak Darurat',
          icon: Icons.add,
          onPressed: onAddContact,
        ),
      ),
    );
  }
}

class LoadedContactCard extends StatelessWidget {
  const LoadedContactCard({
    super.key,
    required this.contact,
    this.contacts = const [],
    required this.onEdit,
    this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
    this.onAddMore,
  });

  final EmergencyContact contact;
  final List<EmergencyContact> contacts;
  final void Function(EmergencyContact contact) onEdit;
  final void Function(EmergencyContact contact)? onDelete;
  final void Function(int index)? onMoveUp;
  final void Function(int index)? onMoveDown;
  final VoidCallback? onAddMore;

  @override
  Widget build(BuildContext context) {
    final list = contacts.isNotEmpty ? contacts : [contact];

    return AppCard(
      key: const Key('contact-data-state'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kontak darurat aktif',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (list.length < 5 && onAddMore != null)
                TextButton.icon(
                  onPressed: onAddMore,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Kontak'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) const Divider(height: 24),
            _ContactItemRow(
              index: i,
              total: list.length,
              contact: list[i],
              onEdit: () => onEdit(list[i]),
              onDelete: onDelete != null ? () => onDelete!(list[i]) : null,
              onMoveUp: onMoveUp != null && i > 0 ? () => onMoveUp!(i) : null,
              onMoveDown: onMoveDown != null && i < list.length - 1
                  ? () => onMoveDown!(i)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactItemRow extends StatelessWidget {
  const _ContactItemRow({
    required this.index,
    required this.total,
    required this.contact,
    required this.onEdit,
    this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  final int index;
  final int total;
  final EmergencyContact contact;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (total > 1) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Prioritas #${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (onMoveUp != null)
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  tooltip: 'Pindahkan ke atas',
                  onPressed: onMoveUp,
                  visualDensity: VisualDensity.compact,
                ),
              if (onMoveDown != null)
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  tooltip: 'Pindahkan ke bawah',
                  onPressed: onMoveDown,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        _InfoRow(icon: Icons.person_outline, text: contact.name),
        const SizedBox(height: 8),
        _InfoRow(icon: Icons.phone_outlined, text: contact.phoneNumber),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Ubah Kontak'),
            ),
            if (onDelete != null)
              TextButton.icon(
                onPressed: onDelete,
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus'),
              ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
