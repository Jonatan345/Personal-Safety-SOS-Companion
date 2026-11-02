import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/monitoring_screen.dart';
import '../screens/incident_screen.dart';
import '../screens/history_screen.dart';
import '../screens/contact_setup_screen.dart';

/// Nama rute. Semua `Navigator.pushNamed` harus memakai konstanta ini.
class AppRoutes {
  static const home = '/';
  static const monitoring = '/monitoring';
  static const incident = '/incident';
  static const history = '/history';
  static const contactSetup = '/contact-setup';

  static final Map<String, WidgetBuilder> routes = {
    home: (context) => const HomeScreen(),
    monitoring: (context) => const MonitoringScreen(),
    incident: (context) => const IncidentScreen(),
    history: (context) => const HistoryScreen(),
    contactSetup: (context) => const ContactSetupScreen(),
  };
}
