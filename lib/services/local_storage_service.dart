import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// One shared, idempotent bootstrap for Hive.
/// It can run after the first UI frame, while repositories safely await it
/// before accessing a box.
class LocalStorageService {
  LocalStorageService._();

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
    if (!Hive.isBoxOpen('emergency_contacts_v2')) {
      await Hive.openBox<String>('emergency_contacts_v2');
    }
    if (!Hive.isBoxOpen('incidents_v2')) {
      await Hive.openBox<String>('incidents_v2');
    }
  }
}
