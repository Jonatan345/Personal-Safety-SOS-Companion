import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/incident.dart';
import 'repositories/emergency_contact_repository.dart';
import 'repositories/incident_repository.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(IncidentAdapter());
  await Hive.openBox<Incident>(IncidentRepository.boxName);
  await Hive.openBox<String>(HiveEmergencyContactRepository.boxName);
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
