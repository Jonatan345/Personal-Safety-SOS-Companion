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
    required this.onEdit,
  });

  final EmergencyContact contact;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const Key('contact-data-state'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kontak darurat aktif',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _InfoRow(icon: Icons.person_outline, text: contact.name),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.phone_outlined, text: contact.phoneNumber),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Ubah Kontak'),
          ),
        ],
      ),
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
