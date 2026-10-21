import 'dart:async';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static const _permissionTimeout = Duration(seconds: 12);

  /// Monitoring needs microphone access; location is requested only for SOS.
  Future<PermissionResult> requestMonitoringPermissions() async {
    try {
      final microphone = await _request(Permission.microphone);
      return PermissionResult(microphone: microphone);
    } on TimeoutException {
      return const PermissionResult(
        microphone: PermissionStatus.denied,
        failure: 'Permintaan izin mikrofon melewati batas waktu. Coba lagi.',
      );
    } catch (error) {
      return PermissionResult(
        microphone: PermissionStatus.denied,
        failure: 'Gagal memeriksa izin mikrofon: $error',
      );
    }
  }

  Future<PermissionStatus> _request(Permission permission) async {
    final current = await permission.status.timeout(_permissionTimeout);
    if (current.isGranted || current.isPermanentlyDenied) return current;
    return permission.request().timeout(_permissionTimeout);
  }
}

class PermissionResult {
  const PermissionResult({required this.microphone, this.failure});

  final PermissionStatus microphone;
  final String? failure;

  bool get canMonitor => microphone.isGranted;

  String get message {
    if (failure != null) return failure!;
    if (microphone.isPermanentlyDenied) {
      return 'Izin mikrofon diblokir. Aktifkan izin Mikrofon untuk SOS Companion di Pengaturan aplikasi.';
    }
    return 'Izin mikrofon diperlukan untuk deteksi suara sekitar.';
  }
}
