import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/incident.dart';
import '../notifiers/incident_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class IncidentScreen extends ConsumerStatefulWidget {
  const IncidentScreen({super.key});

  @override
  ConsumerState<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends ConsumerState<IncidentScreen> {
  int secondsLeft = 10;
  Timer? timer;
  bool _isCompleting = false;

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
    setState(() => _isCompleting = true);
    timer?.cancel();

    final incident = Incident(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      latitude: -6.2088,
      longitude: 106.8456,
      status: status,
    );

    try {
      await ref.read(incidentNotifierProvider.notifier).addIncident(incident);
    } catch (error) {
      debugPrint('Failed to save incident history: $error');
      if (!mounted) return;
      setState(() => _isCompleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Riwayat insiden gagal disimpan.')),
      );
      return;
    }

    if (!mounted) return;
    if (status == 'sent') {
      Navigator.pushReplacementNamed(context, '/history');
    } else {
      Navigator.pop(context);
    }
  }

  void _cancel() {
    _finishIncident('cancelled');
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.danger,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Insiden Terdeteksi',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Alert akan dikirim ke kontak darurat Anda dalam',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  '$secondsLeft',
                  style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger),
                ),
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                label: _isCompleting
                    ? 'Menyimpan Riwayat...'
                    : 'Batalkan (Ini Bukan Darurat)',
                color: Colors.white,
                onPressed: _isCompleting ? null : _cancel,
                loading: _isCompleting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
