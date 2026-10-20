import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'repositories/emergency_contact_repository.dart';
import 'repositories/incident_repository.dart';
import 'routes/app_routes.dart';
import 'services/alert_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Hive.openBox<String>(HiveEmergencyContactRepository.boxName);
  await Hive.openBox<String>(IncidentRepository.boxName);
  await AlertService.instance.initialise();
  runApp(const ProviderScope(child: SosCompanionApp()));
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
