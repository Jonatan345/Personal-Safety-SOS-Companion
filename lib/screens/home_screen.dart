import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/emergency_contact_notifier.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/responsive_body.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS Companion')),
      body: ResponsiveBody(
        builder: (context, wide) {
          final status = _ReadinessCard(
            onStart: () => Navigator.pushNamed(context, AppRoutes.monitoring),
            onSetupContact: () =>
                Navigator.pushNamed(context, AppRoutes.contactSetup),
          );
          final menu = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MenuTile(
                  icon: Icons.contact_phone_outlined,
                  label: 'Kontak Darurat',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.contactSetup),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MenuTile(
                  icon: Icons.history,
                  label: 'Riwayat',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.history),
                ),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 24),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: status),
                    const SizedBox(width: 24),
                    Expanded(child: menu),
                  ],
                )
              else ...[
                status,
                const SizedBox(height: 16),
                menu,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    // Semantics bukan const constructor, jadi Column tidak boleh const.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          label: 'Selamat datang',
          excludeSemantics: true,
          child: const Text(
            'Selamat datang 👋',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pantau keamanan Anda secara otomatis lewat sensor HP.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Kesiapan SOS berdasarkan data nyata: apakah kontak darurat sudah tersimpan.
class _Readiness {
  const _Readiness({
    required this.icon,
    required this.color,
    required this.text,
    this.needsContact = false,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool needsContact;
}

class _ReadinessCard extends ConsumerWidget {
  const _ReadinessCard({required this.onStart, required this.onSetupContact});

  final VoidCallback onStart;
  final VoidCallback onSetupContact;

  _Readiness _describe(AsyncValue<EmergencyContactViewState> contact) {
    return contact.when(
      loading: () => const _Readiness(
        icon: Icons.hourglass_empty,
        color: AppColors.textSecondary,
        text: 'Memeriksa kontak darurat…',
      ),
      error: (_, __) => const _Readiness(
        icon: Icons.error_outline,
        color: AppColors.danger,
        text: 'Kontak darurat tidak dapat dimuat.',
        needsContact: true,
      ),
      data: (state) => state.hasContact
          ? _Readiness(
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              text: 'Alert akan disiapkan untuk ${state.contact!.name}.',
            )
          : const _Readiness(
              icon: Icons.warning_amber_rounded,
              color: AppColors.danger,
              text: 'Belum ada kontak darurat. Atur dulu agar SMS alert '
                  'bisa disiapkan.',
              needsContact: true,
            ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readiness = _describe(ref.watch(emergencyContactNotifierProvider));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kesiapan SOS',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(readiness.icon, color: readiness.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    readiness.text,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          if (readiness.needsContact)
            TextButton(
              onPressed: onSetupContact,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: const Text('Atur Kontak Darurat'),
            ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Mulai Monitoring',
            icon: Icons.play_circle_outline,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
