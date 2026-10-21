import 'dart:async';

import 'package:flutter/material.dart';

import '../services/monitoring_service.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({
    super.key,
    this.permissionService,
    this.monitoringFactory,
  });

  @visibleForTesting
  final PermissionService? permissionService;

  @visibleForTesting
  final MonitoringServiceFactory? monitoringFactory;

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  static const _permissionFlowTimeout = Duration(seconds: 25);
  static const _sensorStartTimeout = Duration(seconds: 7);
  static const _cleanupTimeout = Duration(seconds: 3);

  late final PermissionService _permissions;
  late final MonitoringServiceFactory _monitoringFactory;
  MonitoringController? _monitoring;
  bool _loading = true;
  String? _error;
  int _startAttempt = 0;
  bool _triggerHandled = false;

  @override
  void initState() {
    super.initState();
    _permissions = widget.permissionService ?? PermissionService();
    _monitoringFactory = widget.monitoringFactory ??
        ({required onTrigger, required onError}) => MonitoringService(
              onTrigger: onTrigger,
              onError: onError,
            );
    _start();
  }

  Future<void> _start() async {
    final attempt = ++_startAttempt;
    var startingSensors = false;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _disposeMonitoring();
      if (!_isCurrentAttempt(attempt)) return;

      final result = await _permissions
          .requestMonitoringPermissions()
          .timeout(_permissionFlowTimeout);
      if (!_isCurrentAttempt(attempt)) return;
      if (!result.canMonitor) {
        _showFailure(attempt, result.message);
        return;
      }

      late final MonitoringController service;
      service = _monitoringFactory(
        onTrigger: (source) => _onTrigger(source, attempt, service),
        onError: (error) => _onSensorError(error, attempt, service),
      );
      _monitoring = service;
      startingSensors = true;
      await service.start().timeout(_sensorStartTimeout);
      if (_isCurrentAttempt(attempt)) {
        setState(() => _loading = false);
      }
    } catch (error) {
      if (!_isCurrentAttempt(attempt)) return;
      final message = error is TimeoutException
          ? startingSensors
              ? 'Sensor belum siap. Periksa izin mikrofon dan sensor, lalu coba lagi.'
              : 'Permintaan izin mikrofon melewati batas waktu. Coba lagi.'
          : 'Monitoring gagal dimulai: $error';
      await _handleStartFailure(attempt, message);
    }
  }

  bool _isCurrentAttempt(int attempt) => mounted && attempt == _startAttempt;

  Future<void> _disposeMonitoring() async {
    final service = _monitoring;
    if (service == null) return;
    await service.dispose().timeout(_cleanupTimeout);
    if (identical(_monitoring, service)) _monitoring = null;
  }

  Future<void> _handleStartFailure(int attempt, String message) async {
    try {
      await _disposeMonitoring();
    } catch (cleanupError) {
      message = '$message Pembersihan sensor juga gagal: $cleanupError';
    }
    _showFailure(attempt, message);
  }

  void _showFailure(int attempt, String message) {
    if (!_isCurrentAttempt(attempt)) return;
    setState(() {
      _loading = false;
      _error = message;
    });
  }

  void _onSensorError(
    Object error,
    int attempt,
    MonitoringController service,
  ) {
    if (!_isCurrentAttempt(attempt) || !identical(_monitoring, service)) return;
    _showFailure(attempt, 'Sensor berhenti bekerja: $error');
    unawaited(_disposeMonitoring().catchError((Object cleanupError) {
      _showFailure(
        attempt,
        'Sensor berhenti bekerja: $error. '
        'Pembersihan sensor gagal: $cleanupError',
      );
    }));
  }

  void _onTrigger(
      TriggerSource source, int attempt, MonitoringController service) {
    if (!_isCurrentAttempt(attempt) ||
        !identical(_monitoring, service) ||
        _triggerHandled) {
      return;
    }
    _triggerHandled = true;
    Navigator.pushNamed(context, '/incident', arguments: source.name);
  }

  @override
  void dispose() {
    _startAttempt++;
    final service = _monitoring;
    if (service != null) {
      unawaited(service.dispose().catchError((Object error) {
        debugPrint('Failed to stop monitoring sensors: $error');
      }));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Monitoring')),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                const Icon(Icons.lock_outline,
                                    size: 48, color: AppColors.danger),
                                const SizedBox(height: 12),
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                    onPressed: _start,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Coba lagi')),
                              ]))
                        : Column(children: [
                            AppCard(
                                child: Column(children: [
                              Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                      color: AppColors.success
                                          .withValues(alpha: .12),
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.sensors,
                                      size: 40, color: AppColors.success)),
                              const SizedBox(height: 14),
                              const Text('Sensor Aktif',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              const Text(
                                  'Gerakan dan suara sekitar sedang dipantau.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                            ])),
                            const SizedBox(height: 16),
                            const _SensorRow(
                                label: 'Accelerometer',
                                value: 'Deteksi shake/fall',
                                icon: Icons.vibration),
                            const SizedBox(height: 10),
                            const _SensorRow(
                                label: 'GPS',
                                value: 'Diambil saat insiden',
                                icon: Icons.location_on_outlined),
                            const SizedBox(height: 10),
                            const _SensorRow(
                                label: 'Mikrofon',
                                value: 'Ambang 85 dB',
                                icon: Icons.mic_none),
                            const Spacer(),
                            PrimaryButton(
                                label: 'Simulasikan Shake/Fall',
                                icon: Icons.warning_amber_rounded,
                                color: AppColors.danger,
                                onPressed: () => _monitoring?.simulateMotion()),
                            const SizedBox(height: 10),
                            PrimaryButton(
                                label: 'Hentikan Monitoring',
                                color: AppColors.textSecondary,
                                onPressed: () => Navigator.pop(context)),
                          ]))),
      );
}

class _SensorRow extends StatelessWidget {
  const _SensorRow(
      {required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(value,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13))
      ]));
}
