import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<PermissionResult> requestMonitoringPermissions() async {
    final location = await Permission.locationWhenInUse.request();
    final microphone = await Permission.microphone.request();
    final notification = await Permission.notification.request();
    return PermissionResult(location: location, microphone: microphone, notification: notification);
  }
}

class PermissionResult {
  const PermissionResult({required this.location, required this.microphone, required this.notification});
  final PermissionStatus location;
  final PermissionStatus microphone;
  final PermissionStatus notification;
  bool get canMonitor => location.isGranted && microphone.isGranted;
  String get message {
    if (!location.isGranted) return 'Izin lokasi diperlukan agar alert memuat posisi Anda.';
    if (!microphone.isGranted) return 'Izin mikrofon diperlukan untuk deteksi suara sekitar.';
    return 'Izin diperlukan belum diberikan.';
  }
}
