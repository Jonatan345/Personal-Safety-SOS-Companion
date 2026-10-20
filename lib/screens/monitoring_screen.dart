import 'package:flutter/material.dart';

import '../services/monitoring_service.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});
  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  final _permissions = PermissionService();
  MonitoringService? _monitoring;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _start(); }

  Future<void> _start() async {
    setState(() { _loading = true; _error = null; });
    final result = await _permissions.requestMonitoringPermissions();
    if (!result.canMonitor) {
      if (mounted) setState(() { _loading = false; _error = result.message; });
      return;
    }
    _monitoring = MonitoringService(onTrigger: _onTrigger);
    try { await _monitoring!.start(); if (mounted) setState(() => _loading = false); }
    catch (error) { if (mounted) setState(() { _loading = false; _error = 'Sensor tidak dapat dimulai: $error'; }); }
  }

  void _onTrigger(TriggerSource source) { if (mounted) Navigator.pushNamed(context, '/incident', arguments: source.name); }
  @override
  void dispose() { _monitoring?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Monitoring')),
    body: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: _loading
      ? const Center(child: CircularProgressIndicator())
      : _error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline, size: 48, color: AppColors.danger), const SizedBox(height: 12), Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 16),
          FilledButton.icon(onPressed: _start, icon: const Icon(Icons.refresh), label: const Text('Minta izin lagi')),
        ]))
      : Column(children: [
          AppCard(child: Column(children: [
            Container(width: 90, height: 90, decoration: BoxDecoration(color: AppColors.success.withValues(alpha: .12), shape: BoxShape.circle), child: const Icon(Icons.sensors, size: 40, color: AppColors.success)),
            const SizedBox(height: 14), const Text('Sensor Aktif', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)), const SizedBox(height: 4), const Text('Gerakan dan suara sekitar sedang dipantau.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          ])),
          const SizedBox(height: 16), const _SensorRow(label: 'Accelerometer', value: 'Deteksi shake/fall', icon: Icons.vibration), const SizedBox(height: 10), const _SensorRow(label: 'GPS', value: 'Diambil saat insiden', icon: Icons.location_on_outlined), const SizedBox(height: 10), const _SensorRow(label: 'Mikrofon', value: 'Ambang 85 dB', icon: Icons.mic_none),
          const Spacer(), PrimaryButton(label: 'Simulasikan Shake/Fall', icon: Icons.warning_amber_rounded, color: AppColors.danger, onPressed: () => _monitoring?.simulateMotion()), const SizedBox(height: 10), PrimaryButton(label: 'Hentikan Monitoring', color: AppColors.textSecondary, onPressed: () => Navigator.pop(context)),
        ]))),
  );
}

class _SensorRow extends StatelessWidget {
  const _SensorRow({required this.label, required this.value, required this.icon});
  final String label, value; final IconData icon;
  @override
  Widget build(BuildContext context) => AppCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [Icon(icon, color: AppColors.primary, size: 20), const SizedBox(width: 12), Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))), Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))]));
}
