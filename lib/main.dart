import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes/app_routes.dart';
import 'services/alert_service.dart';
import 'services/app_logger.dart';
import 'services/local_storage_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_info.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorLogging();
  AppLogger.instance.info('app', 'Aplikasi dimulai (versi ${AppInfo.label})');
  runApp(const ProviderScope(child: SosCompanionApp()));
  unawaited(_warmUpDeviceServices());
}

/// Semua error Flutter dan error async yang tidak tertangani masuk ke log.
void _installErrorLogging() {
  FlutterError.onError = (details) {
    AppLogger.instance.error(
      'flutter',
      details.exceptionAsString(),
      null,
      details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.instance.error('platform', 'Error tidak tertangani', error, stack);
    return true;
  };
}

/// Starts after the first frame so storage and platform setup cannot keep the
/// app on a blank splash screen. Repositories wait on [LocalStorageService]
/// before reading boxes.
Future<void> _warmUpDeviceServices() async {
  try {
    await LocalStorageService.ensureReady();
    await AppLogger.instance.enablePersistence();
  } catch (error, stack) {
    AppLogger.instance.error('app', 'Penyimpanan lokal gagal disiapkan', error, stack);
  }
  try {
    await AlertService.instance.initialise();
  } catch (error, stack) {
    AppLogger.instance.error('app', 'Notifikasi gagal disiapkan', error, stack);
  }
}

class SosCompanionApp extends StatelessWidget {
  const SosCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOS Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}
