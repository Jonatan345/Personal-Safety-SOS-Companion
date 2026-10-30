import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency_contact.dart';
import '../models/incident.dart';
import '../notifiers/incident_notifier.dart';
import '../repositories/emergency_contact_repository.dart';
import '../services/alert_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../utils/sos_message.dart';
import '../widgets/primary_button.dart';

class IncidentScreen extends ConsumerStatefulWidget {
  const IncidentScreen({super.key, this.locationProvider, this.alerts});
  final Future<IncidentLocation> Function()? locationProvider;
  final AlertGateway? alerts;
  @override
  ConsumerState<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends ConsumerState<IncidentScreen> {
  int secondsLeft = 10;
  Timer? timer;
  bool _isCompleting = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft <= 1) {
        t.cancel();
        _finishIncident('sent');
      } else {
        setState(() => secondsLeft--);
      }
    });
  }

  Future<void> _finishIncident(String status) async {
    if (!mounted || _isCompleting) return;
    setState(() {
      _isCompleting = true;
      _error = null;
    });
    timer?.cancel();

    // Ambil semua dependensi sebelum await pertama: alert tetap berjalan
    // walaupun layar ini sudah ditutup.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final incidents = ref.read(incidentNotifierProvider.notifier);
    final contacts = ref.read(emergencyContactRepositoryProvider);
    final alerts = widget.alerts ?? AlertService.instance;

    try {
      double? latitude;
      double? longitude;
      String? locationFailure;
      if (status == 'sent') {
        try {
          final position = await (widget.locationProvider?.call() ??
              LocationService().currentPosition());
          latitude = position.latitude;
          longitude = position.longitude;
        } catch (error) {
          // Lokasi gagal: simpan null (bukan 0,0) dan beri tahu pengguna.
          locationFailure = locationFailureMessage(error);
        }
      }
      await incidents.addIncident(Incident(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          timestamp: DateTime.now(),
          latitude: latitude,
          longitude: longitude,
          status: status));

      if (status != 'sent') {
        if (mounted) navigator.pop();
        return;
      }

      EmergencyContact? contact;
      String? contactFailure;
      try {
        contact = await contacts.fetchContact();
      } catch (_) {
        contactFailure = 'Kontak darurat tidak dapat dimuat.';
      }

      final notes = <String>[
        if (locationFailure != null)
          '$locationFailure Alert tetap dikirim tanpa lokasi.',
        if (contactFailure != null) contactFailure,
        if (contact == null && contactFailure == null)
          'Kontak darurat belum diatur, SMS tidak disiapkan.',
      ];
      final message = buildSosMessage(latitude: latitude, longitude: longitude);

      if (mounted) navigator.pushReplacementNamed('/history');
      // Kanal platform (notifikasi/SMS) tidak boleh menunda penyimpanan
      // insiden maupun perpindahan ke riwayat.
      unawaited(_dispatchAlerts(
        alerts: alerts,
        messenger: messenger,
        contact: contact,
        message: message,
        notes: notes,
      ));
    } catch (error) {
      if (mounted) {
        setState(() {
          _isCompleting = false;
          _error = '$error';
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
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.danger,
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.white, size: 56),
                    const SizedBox(height: 16),
                    const Text('Mendeteksi Insiden',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text('Alert akan dikirim dalam $secondsLeft detik',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 24),
                    Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text('$secondsLeft',
                            style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                color: AppColors.danger))),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text('Gagal: $_error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white))),
                    const SizedBox(height: 32),
                    PrimaryButton(
                        label: _isCompleting
                            ? 'Mengambil lokasi...'
                            : 'Batalkan (Ini Bukan Darurat)',
                        color: Colors.white,
                        onPressed: _isCompleting
                            ? null
                            : () => _finishIncident('cancelled'),
                        loading: _isCompleting),
                  ]))));
}

/// Mengirim notifikasi lalu SMS. Setiap kegagalan ditampilkan ke pengguna
/// lewat SnackBar (tidak ada lagi error yang ditelan diam-diam).
Future<void> _dispatchAlerts({
  required AlertGateway alerts,
  required ScaffoldMessengerState messenger,
  required EmergencyContact? contact,
  required String message,
  required List<String> notes,
}) async {
  final notificationFailure = await alerts.showEmergencyNotification(
    contact == null
        ? 'Insiden tersimpan. Atur kontak untuk mengirim SMS.'
        : 'Alert siap dikirim ke ${contact.name}.',
  );
  if (notificationFailure != null) notes.add(notificationFailure);
  // Tampilkan sebelum SMS dibuka, karena aplikasi SMS memindahkan app ke latar.
  _showNotes(messenger, notes);

  if (contact == null) return;
  final smsFailure = await alerts.openSmsComposer(
    phone: contact.phoneNumber,
    message: message,
  );
  if (smsFailure != null) _showNotes(messenger, [smsFailure]);
}

void _showNotes(ScaffoldMessengerState messenger, List<String> notes) {
  if (notes.isEmpty || !messenger.mounted) return;
  messenger.showSnackBar(SnackBar(
    content: Text(notes.join('\n')),
    duration: const Duration(seconds: 10),
    showCloseIcon: true,
  ));
}
