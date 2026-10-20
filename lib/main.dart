import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes/app_routes.dart';
import 'services/alert_service.dart';
import 'services/local_storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SosCompanionApp()));

  // No platform/storage work may block the first Flutter frame. Android keeps
  // the launch splash on screen until that first frame has been rendered.
  unawaited(_warmUpDeviceServices());
}

Future<void> _warmUpDeviceServices() async {
  try {
    await LocalStorageService.ensureReady();
  } catch (_) {
    // Individual data screens already expose an error state and retry path.
  }
  try {
    await AlertService.instance.initialise();
  } catch (_) {
    // Notifications are optional for opening the app.
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

