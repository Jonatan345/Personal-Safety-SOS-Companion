import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/incident_status.dart';
import '../notifiers/incident_notifier.dart';
import '../repositories/emergency_contact_repository.dart';
import '../routes/app_routes.dart';
import '../services/alert_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../use_cases/incident_reporter.dart';
import '../utils/app_config.dart';
import '../utils/error_messages.dart';
import '../utils/snackbars.dart';
import '../widgets/primary_button.dart';

/// Layar hitung mundur insiden. Layar ini hanya mengurus tampilan, timer, dan
/// navigasi; alur lokasi, penyimpanan, dan alert ada di [IncidentReporter].
class IncidentScreen extends ConsumerStatefulWidget {
  const IncidentScreen({
    super.key,
    this.locationProvider,
    this.alerts,
    this.source,
    this.countdownSeconds,
  });

  final Future<IncidentLocation> Function()? locationProvider;
  final AlertGateway? alerts;
  final String? source;
  final int? countdownSeconds;

  @override
  ConsumerState<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends ConsumerState<IncidentScreen> {
  late int secondsLeft;
  Timer? timer;
  bool _isCompleting = false;
  String? _pendingStatus;
  String? _error;
  String? _source;
  bool _initializedArgs = false;

  @override
  void initState() {
    super.initState();
    _source = widget.source;
    secondsLeft = widget.countdownSeconds ??
        (_source == 'manual' ? 3 : SosConfig.countdownSeconds);
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
      _initializedArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && _source == null) {
        _source = args;
        if (widget.countdownSeconds == null && _source == 'manual') {
          setState(() {
            secondsLeft = 3;
          });
        }
      } else if (args is Map<String, dynamic>) {
        if (_source == null && args['source'] is String) {
          _source = args['source'] as String;
        }
        if (widget.countdownSeconds == null && args['countdown'] is int) {
          setState(() {
            secondsLeft = args['countdown'] as int;
          });
        }
      }
    }
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft <= 1) {
        t.cancel();
        _finishIncident(IncidentStatus.sent);
      } else {
        setState(() => secondsLeft--);
      }
    });
  }

  IncidentReporter _createReporter() => IncidentReporter(
        locate: widget.locationProvider ?? LocationService().currentPosition,
        save: ref.read(incidentNotifierProvider.notifier).addIncident,
        loadContacts:
            ref.read(emergencyContactRepositoryProvider).fetchContacts,
        alerts: widget.alerts ?? AlertService.instance,
      );

  Future<void> _finishIncident(String status) async {
    if (!mounted || _isCompleting) return;
    setState(() {
      _isCompleting = true;
      _pendingStatus = status;
      _error = null;
    });
    timer?.cancel();

    // Ambil dependensi sebelum await pertama: alert tetap berjalan walaupun
    // layar ini sudah ditutup.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final reporter = _createReporter();

    try {
      final report = await reporter.report(status, source: _source);
      if (!report.isSent) {
        if (report.notes.isNotEmpty) {
          showMessage(messenger, report.notes.join('\n'));
        }
        if (mounted) navigator.pop();
        return;
      }

      if (mounted) navigator.pushReplacementNamed(AppRoutes.history);
      // Kanal platform (notifikasi/SMS) tidak boleh menunda penyimpanan
      // insiden maupun perpindahan ke riwayat.
      unawaited(reporter.dispatch(
        report,
        (notes) => showMessage(
          messenger,
          notes.join('\n'),
          duration: const Duration(seconds: 10),
          dismissible: true,
        ),
      ));
    } catch (error) {
      if (mounted) {
        setState(() {
          _isCompleting = false;
          _error = userMessageFor(error);
        });
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pembaca layar hanya diumumkan pada 5 detik terakhir agar tidak berisik.
    final countdownLabel = secondsLeft <= 5
        ? '$secondsLeft detik tersisa'
        : 'Alert akan dikirim dalam hitungan detik';

    // Tombol kembali sistem berarti "ini bukan darurat": dicatat sebagai
    // dibatalkan, bukan hilang tanpa jejak.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finishIncident(IncidentStatus.cancelled);
      },
      child: Scaffold(
        backgroundColor: AppColors.danger,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0.0, constraints.maxHeight - 48),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _buildContent(countdownLabel),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(String countdownLabel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 56),
        const SizedBox(height: 16),
        Text(
          _source == 'manual' ? 'SOS Manual Dipicu' : 'Mendeteksi Insiden',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Alert akan dikirim dalam $secondsLeft detik',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 24),
        Semantics(
          liveRegion: true,
          label: countdownLabel,
          excludeSemantics: true,
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$secondsLeft',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: AppColors.danger,
              ),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: _isCompleting
              ? (_pendingStatus == IncidentStatus.cancelled
                  ? 'Membatalkan...'
                  : 'Mengambil lokasi...')
              : 'Batalkan (Ini Bukan Darurat)',
          color: Colors.white,
          foregroundColor: AppColors.danger,
          onPressed: _isCompleting
              ? null
              : () => _finishIncident(IncidentStatus.cancelled),
          loading: _isCompleting,
          loadingLabel: _pendingStatus == IncidentStatus.cancelled
              ? 'Membatalkan...'
              : 'Mengambil lokasi...',
        ),
      ],
    );
  }
}
