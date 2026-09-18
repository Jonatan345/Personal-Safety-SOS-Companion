import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/app_card.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  bool isActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monitoring')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              AppCard(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.success.withValues(alpha: 0.12) : AppColors.border,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sensors,
                        size: 40,
                        color: isActive ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isActive ? 'Sensor Aktif' : 'Sensor Nonaktif',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Accelerometer & mikrofon sedang memantau pergerakan Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _SensorRow(label: 'Accelerometer', value: 'Normal', icon: Icons.vibration),
              const SizedBox(height: 10),
              const _SensorRow(label: 'GPS', value: 'Siap', icon: Icons.location_on_outlined),
              const SizedBox(height: 10),
              const _SensorRow(label: 'Mikrofon', value: 'Mendengarkan', icon: Icons.mic_none),
              const Spacer(),
              PrimaryButton(
                label: 'Simulasikan Insiden',
                icon: Icons.warning_amber_rounded,
                color: AppColors.danger,
                onPressed: () => Navigator.pushNamed(context, '/incident'),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: 'Hentikan Monitoring',
                color: AppColors.textSecondary,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensorRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SensorRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
