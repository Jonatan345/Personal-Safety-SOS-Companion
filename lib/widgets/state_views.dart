import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tampilan loading bersama (Riwayat, Kontak, Monitoring).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Memuat…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tampilan kosong / gagal bersama: ikon, judul, pesan, dan tombol aksi opsional.
class StateMessageView extends StatelessWidget {
  const StateMessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.iconColor = AppColors.textSecondary,
    this.action,
    this.announce = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Color iconColor;
  final Widget? action;

  /// true untuk keadaan gagal agar pembaca layar langsung mengumumkannya.
  final bool announce;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: iconColor),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: announce,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 16),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
