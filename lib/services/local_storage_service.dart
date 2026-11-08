import 'package:hive_flutter/hive_flutter.dart';

/// One shared, idempotent bootstrap for Hive.
/// It can run after the first UI frame, while repositories safely await it
/// before accessing a box.
class LocalStorageService {
  LocalStorageService._();

  // Versioned namespaces avoid reading incompatible Hive data from older demos.
  // Satu-satunya tempat nama box didefinisikan.
  static const contactsBox = 'emergency_contacts_v2';
  static const incidentsBox = 'incidents_v2';
  static const logsBox = 'app_logs_v1';

  static Future<void>? _ready;

  static Future<void> ensureReady() async {
    final activeInitialisation = _ready ??= _open();
    try {
      await activeInitialisation;
    } catch (_) {
      if (identical(_ready, activeInitialisation)) _ready = null;
      rethrow;
    }
  }

  static Future<void> _open() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(contactsBox)) {
      await Hive.openBox<String>(contactsBox);
    }
    if (!Hive.isBoxOpen(incidentsBox)) {
      await Hive.openBox<String>(incidentsBox);
    }
    if (!Hive.isBoxOpen(logsBox)) {
      await Hive.openBox<String>(logsBox);
    }
  }
}
