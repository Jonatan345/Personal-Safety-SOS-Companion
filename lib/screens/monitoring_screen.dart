import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../routes/app_routes.dart';
import '../services/app_logger.dart';
import '../services/monitoring_service.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_config.dart';
import '../utils/error_messages.dart';
import '../utils/snackbars.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/responsive_body.dart';
import '../widgets/state_views.dart';

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

      // Izin notifikasi bukan prasyarat monitoring: diminta tanpa memblokir
      // sensor dan tanpa ditunggu.
      unawaited(_requestNotificationPermission(attempt));

      late final MonitoringController service;
      service = _monitoringFactory(
        onTrigger: (source) => _onTrigger(source, attempt, service),
        onError: (error) => _onSensorError(error, attempt, service),
      );
      _monitoring = service;
      startingSensors = true;
      await service.start().timeout(_sensorStartTimeout);
      if (_isCurrentAttempt(attempt)) {
        AppLogger.instance.info('monitoring', 'Sensor aktif');
        setState(() => _loading = false);
      }
    } catch (error) {
      if (!_isCurrentAttempt(attempt)) return;
      final message = error is TimeoutException
          ? startingSensors
              ? 'Sensor belum siap. Periksa izin mikrofon dan sensor, lalu coba lagi.'
              : 'Permintaan izin mikrofon melewati batas waktu. Coba lagi.'
          : 'Monitoring gagal dimulai. ${userMessageFor(error)}';
      await _handleStartFailure(attempt, message);
    }
  }

  bool _isCurrentAttempt(int attempt) => mounted && attempt == _startAttempt;

  Future<void> _requestNotificationPermission(int attempt) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await _permissions.requestNotificationPermission();
    final message = result.message;
    if (!_isCurrentAttempt(attempt) || message == null) return;
    showMessage(
      messenger,
      message,
      duration: const Duration(seconds: 10),
      dismissible: true,
      replace: true,
      action: result.needsSettings
          ? SnackBarAction(label: 'Pengaturan', onPressed: openAppSettings)
          : null,
    );
  }

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
      debugPrint('Pembersihan sensor gagal: $cleanupError');
      message = '$message Pembersihan sensor juga gagal.';
    }
    _showFailure(attempt, message);
  }

  void _showFailure(int attempt, String message) {
    if (!_isCurrentAttempt(attempt)) return;
    AppLogger.instance.error('monitoring', message);
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
    _showFailure(attempt, 'Sensor berhenti bekerja. ${userMessageFor(error)}');
    unawaited(_disposeMonitoring().catchError((Object cleanupError) {
      debugPrint('Pembersihan sensor gagal: $cleanupError');
      _showFailure(
        attempt,
        'Sensor berhenti bekerja. ${userMessageFor(error)} '
        'Pembersihan sensor juga gagal.',
      );
    }));
  }

  Future<void> _onTrigger(
    TriggerSource source,
    int attempt,
    MonitoringController service,
  ) async {
    if (!_isCurrentAttempt(attempt) ||
        !identical(_monitoring, service) ||
        _triggerHandled) {
      return;
    }
    _triggerHandled = true;
    AppLogger.instance.info('monitoring', 'Pemicu terdeteksi: ${source.name}');
    try {
      await Navigator.pushNamed(context, AppRoutes.incident,
          arguments: source.name);
    } finally {
      // Monitoring harus tetap mendeteksi insiden berikutnya setelah pengguna
      // membatalkan atau kembali dari layar insiden.
      _triggerHandled = false;
    }
  }

  void _stop() {
    showMessage(ScaffoldMessenger.of(context), 'Monitoring dihentikan');
    Navigator.pop(context);
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
        body: ResponsiveBody(
          fillHeight: true,
          builder: (context, wide) {
            if (_loading) {
              return const LoadingView(label: 'Memulai monitoring sensor…');
            }
            if (_error != null) return _buildError();
            return _buildActive(wide);
          },
        ),
      );

  Widget _buildError() => StateMessageView(
        icon: Icons.lock_outline,
        iconColor: AppColors.danger,
        title: _error!,
        announce: true,
        action: FilledButton.icon(
          onPressed: _start,
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          icon: const Icon(Icons.refresh),
          label: const Text('Coba lagi'),
        ),
      );

  Widget _buildActive(bool wide) {
    final status = AppCard(
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sensors,
              size: 40,
              color: AppColors.success,
              semanticLabel: 'Sensor aktif',
            ),
          ),
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: const Text(
              'Sensor Aktif',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gerakan dan suara sekitar sedang dipantau.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );

    final sensors = Column(
      children: [
        const _SensorRow(
          label: 'Accelerometer',
          value: 'Deteksi shake/fall',
          icon: Icons.vibration,
        ),
        const SizedBox(height: 10),
        const _SensorRow(
          label: 'GPS',
          value: 'Diambil saat insiden',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 10),
        _SensorRow(
          label: 'Mikrofon',
          value: 'Ambang ${SosConfig.soundThresholdDb.round()} dB',
          icon: Icons.mic_none,
        ),
      ],
    );

    final actions = Column(
      children: [
        // Tombol uji hanya untuk build debug/profile; build rilis memakai sensor.
        if (!kReleaseMode) ...[
          PrimaryButton(
            label: 'Simulasikan Shake/Fall',
            icon: Icons.warning_amber_rounded,
            color: AppColors.danger,
            onPressed: () => _monitoring?.simulateMotion(),
          ),
          const SizedBox(height: 10),
        ],
        PrimaryButton(
          label: 'Hentikan Monitoring',
          color: AppColors.textSecondary,
          onPressed: _stop,
        ),
      ],
    );

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [status, const SizedBox(height: 16), sensors],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(child: actions),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        status,
        const SizedBox(height: 16),
        sensors,
        const SizedBox(height: 20),
        actions,
      ],
    );
  }
}

class _SensorRow extends StatelessWidget {
  const _SensorRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20, semanticLabel: ''),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
