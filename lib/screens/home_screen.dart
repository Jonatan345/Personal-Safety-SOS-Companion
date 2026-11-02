import 'package:flutter/material.dart';

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
          final status = _StatusCard(
            onStart: () => Navigator.pushNamed(context, AppRoutes.monitoring),
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
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
                  'Status Monitoring',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Nonaktif',
              style: TextStyle(color: AppColors.textSecondary)),
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
