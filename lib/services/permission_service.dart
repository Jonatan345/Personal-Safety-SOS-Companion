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

  /// Izin notifikasi (Android 13+) diminta saat runtime, tetapi BUKAN
  /// prasyarat monitoring. Tidak pernah melempar error.
  Future<NotificationPermissionResult> requestNotificationPermission() async {
    try {
      final status = await _request(Permission.notification);
      return NotificationPermissionResult(status: status);
    } on TimeoutException {
      return const NotificationPermissionResult(
        failure: 'Permintaan izin notifikasi melewati batas waktu. '
            'Notifikasi alert mungkin tidak muncul.',
      );
    } catch (_) {
      return const NotificationPermissionResult();
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

class NotificationPermissionResult {
  const NotificationPermissionResult({this.status, this.failure});

  final PermissionStatus? status;
  final String? failure;

  bool get granted => status?.isGranted ?? false;
  bool get needsSettings => status?.isPermanentlyDenied ?? false;

  /// null = tidak perlu menampilkan pesan.
  String? get message {
    if (failure != null) return failure;
    final current = status;
    if (current == null || current.isGranted) return null;
    if (current.isPermanentlyDenied) {
      return 'Izin notifikasi diblokir. Aktifkan di Pengaturan aplikasi agar '
          'notifikasi alert muncul. SMS ke kontak darurat tetap disiapkan.';
    }
    return 'Izin notifikasi belum diberikan, sehingga notifikasi alert tidak '
        'akan muncul. SMS ke kontak darurat tetap disiapkan.';
  }
}
