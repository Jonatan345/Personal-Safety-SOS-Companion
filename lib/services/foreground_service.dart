import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startMonitoringForegroundTask() {
  FlutterForegroundTask.setTaskHandler(MonitoringTaskHandler());
}

class MonitoringTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop') {
      FlutterForegroundTask.sendDataToMain('stop');
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {}
}

/// Kontrak gateway foreground service agar dapat di-mock pada pengujian.
abstract interface class ForegroundTaskGateway {
  Future<void> init();
  Future<void> startService({required VoidCallback onStopRequested});
  Future<void> stopService();
  Future<void> notifyTriggered();
}

class AppForegroundService implements ForegroundTaskGateway {
  AppForegroundService._();
  static final AppForegroundService instance = AppForegroundService._();

  VoidCallback? _onStopRequested;
  bool _initialized = false;

  void _onReceiveTaskData(Object data) {
    if (data == 'stop') {
      _onStopRequested?.call();
    }
  }

  @override
  Future<void> init() async {
    if (_initialized) return;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        FlutterForegroundTask.init(
          androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'sos_monitoring_service',
            channelName: 'Monitoring SOS',
            channelDescription:
                'Notifikasi permanen selama monitoring sensor berjalan di latar belakang.',
            channelImportance: NotificationChannelImportance.DEFAULT,
            priority: NotificationPriority.DEFAULT,
            onlyAlertOnce: true,
          ),
          iosNotificationOptions: const IOSNotificationOptions(
            showNotification: false,
            playSound: false,
          ),
          foregroundTaskOptions: ForegroundTaskOptions(
            eventAction: ForegroundTaskEventAction.repeat(5000),
            autoRunOnBoot: false,
            autoRunOnMyPackageReplaced: false,
            allowWakeLock: true,
          ),
        );
      } catch (e) {
        debugPrint('Failed to initialize foreground task: $e');
      }
    }
    _initialized = true;
  }

  @override
  Future<void> startService({required VoidCallback onStopRequested}) async {
    _onStopRequested = onStopRequested;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await init();
        FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
        if (await FlutterForegroundTask.isRunningService) {
          await FlutterForegroundTask.restartService();
        } else {
          await FlutterForegroundTask.startService(
            serviceId: 256,
            notificationTitle: 'Monitoring SOS aktif',
            notificationText:
                'Sensor accelerometer & mikrofon aktif memantau keamanan Anda.',
            notificationButtons: const [
              NotificationButton(id: 'stop', text: 'Hentikan'),
            ],
            notificationInitialRoute: '/monitoring',
            callback: startMonitoringForegroundTask,
          );
        }
      } catch (e) {
        debugPrint('Failed to start foreground service: $e');
      }
    }
  }

  @override
  Future<void> stopService() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
        if (await FlutterForegroundTask.isRunningService) {
          await FlutterForegroundTask.stopService();
        }
      } catch (e) {
        debugPrint('Failed to stop foreground service: $e');
      }
    }
    _onStopRequested = null;
  }

  @override
  Future<void> notifyTriggered() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        FlutterForegroundTask.wakeUpScreen();
        FlutterForegroundTask.launchApp();
      } catch (e) {
        debugPrint('Failed to wake up / launch app from foreground service: $e');
      }
    }
  }
}
