import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/incident.dart';
import '../notifiers/incident_notifier.dart';
import '../repositories/emergency_contact_repository.dart';
import '../services/alert_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class IncidentScreen extends ConsumerStatefulWidget {
  const IncidentScreen({super.key, this.locationProvider});
  final Future<IncidentLocation> Function()? locationProvider;
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
    try {
      var latitude = 0.0, longitude = 0.0;
      if (status == 'sent') {
        try {
          final position = await (widget.locationProvider?.call() ??
              LocationService().currentPosition());
          latitude = position.latitude;
          longitude = position.longitude;
        } catch (_) {
          // The local SOS record remains available when GPS is temporarily off.
        }
      }
      final incident = Incident(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          timestamp: DateTime.now(),
          latitude: latitude,
          longitude: longitude,
          status: status);
      await ref.read(incidentNotifierProvider.notifier).addIncident(incident);
      if (status == 'sent') {
        try {
          final contact =
              await ref.read(emergencyContactRepositoryProvider).fetchContact();
          final message =
              'SOS: kemungkinan insiden terdeteksi. Lokasi saya: https://maps.google.com/?q=$latitude,$longitude';
          // Platform channels (notifications/SMS apps) must never delay saving
          // an SOS record or returning the user to its history.
          unawaited(
            AlertService.instance
                .showEmergencyNotification(
                  contact == null
                      ? 'Insiden tersimpan. Atur kontak untuk mengirim SMS.'
                      : 'Alert siap dikirim ke ${contact.name}.',
                )
                .catchError((_) {}),
          );
          if (contact != null) {
            unawaited(
              AlertService.instance
                  .openSmsComposer(phone: contact.phoneNumber, message: message)
                  .then<void>((_) {}, onError: (_, __) {}),
            );
          }
        } catch (_) {
          // A missing SMS app must not discard a saved emergency incident.
        }
      }
      if (!mounted) return;
      status == 'sent'
          ? Navigator.pushReplacementNamed(context, '/history')
          : Navigator.pop(context);
    } catch (error) {
      if (mounted)
        setState(() {
          _isCompleting = false;
          _error = '$error';
        });
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
