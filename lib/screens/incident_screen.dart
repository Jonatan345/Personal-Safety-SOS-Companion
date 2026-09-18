import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class IncidentScreen extends StatefulWidget {
  const IncidentScreen({super.key});

  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  int secondsLeft = 10;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft <= 1) {
        t.cancel();
        _sendAlert();
      } else {
        setState(() => secondsLeft--);
      }
    });
  }

  void _sendAlert() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/history');
  }

  void _cancel() {
    timer?.cancel();
    Navigator.pop(context);
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
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
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
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  '$secondsLeft',
                  style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: AppColors.danger),
                ),
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                label: 'Batalkan (Ini Bukan Darurat)',
                color: Colors.white,
                onPressed: _cancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
