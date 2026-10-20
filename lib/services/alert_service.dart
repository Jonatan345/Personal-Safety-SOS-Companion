import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertService {
  AlertService._();
  static final AlertService instance = AlertService._();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialise() => _notifications.initialize(
        const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'), iOS: DarwinInitializationSettings()),
      );

  Future<void> showEmergencyNotification(String body) => _notifications.show(
        1,
        'SOS alert dipicu',
        body,
        const NotificationDetails(android: AndroidNotificationDetails('sos_alerts', 'SOS alerts', channelDescription: 'Status alert darurat', importance: Importance.max, priority: Priority.high)),
      );

  Future<bool> openSmsComposer({required String phone, required String message}) {
    final uri = Uri(scheme: 'sms', path: phone, queryParameters: {'body': message});
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
