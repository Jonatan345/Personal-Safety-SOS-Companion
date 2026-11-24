import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Kontrak alert agar bisa diganti pada test. Setiap method tidak pernah
/// melempar error: mengembalikan null jika berhasil, atau alasan gagal yang
/// dapat ditampilkan ke pengguna.
abstract class AlertGateway {
  Future<String?> showEmergencyNotification(
    String body, {
    int? id,
    String? title,
  });
  Future<String?> openSmsComposer({
    required String phone,
    required String message,
  });
}

class AlertService implements AlertGateway {
  AlertService._();
  static final AlertService instance = AlertService._();
  static const _timeout = Duration(seconds: 8);

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  Future<void> initialise() async {
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialised = true;
  }

  @override
  Future<String?> showEmergencyNotification(
    String body, {
    int? id,
    String? title,
  }) async {
    try {
      final status = await Permission.notification.status.timeout(_timeout);
      if (status.isPermanentlyDenied) {
        return 'Izin notifikasi diblokir. Aktifkan di Pengaturan aplikasi '
            'agar notifikasi alert muncul.';
      }
      if (!status.isGranted) {
        return 'Izin notifikasi belum diberikan, notifikasi alert tidak '
            'ditampilkan.';
      }
      if (!_initialised) await initialise();
      // Gunakan ID unik agar insiden tidak saling menimpa (Bug #9)
      final notificationId =
          id ?? (DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF);
      await _notifications
          .show(
            notificationId,
            title ?? 'SOS alert dipicu',
            body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'sos_alerts',
                'SOS alerts',
                channelDescription: 'Status alert darurat',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          )
          .timeout(_timeout);
      return null;
    } catch (_) {
      return 'Notifikasi alert tidak dapat ditampilkan.';
    }
  }

  static Uri createSmsUri({
    required String phone,
    required String message,
  }) {
    return Uri(
      scheme: 'sms',
      path: phone,
      query: 'body=${Uri.encodeComponent(message)}',
    );
  }

  @override
  Future<String?> openSmsComposer({
    required String phone,
    required String message,
  }) async {
    try {
      final uri = createSmsUri(phone: phone, message: message);
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      ).timeout(_timeout);
      return opened
          ? null
          : 'Aplikasi SMS tidak dapat dibuka. Hubungi kontak darurat manual.';
    } catch (_) {
      return 'Aplikasi SMS tidak dapat dibuka. Hubungi kontak darurat manual.';
    }
  }  
}
