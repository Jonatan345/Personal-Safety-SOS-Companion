import 'package:hive/hive.dart';
import '../models/incident.dart';

/// LOCAL DATA & PERSISTENCE LAYER (P5)
/// Storage: Hive (local on-device box)
/// Box opened once in main.dart, accessed here for all CRUD operations.
class IncidentStorageService {
  static const String boxName = 'incidents';

  Box<Incident> get _box => Hive.box<Incident>(boxName);

  // CREATE
  Future<void> addIncident(Incident incident) async {
    await _box.put(incident.id, incident);
  }

  // READ (all, newest first)
  List<Incident> getAllIncidents() {
    final items = _box.values.toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  // READ (single)
  Incident? getIncidentById(String id) {
    return _box.get(id);
  }

  // UPDATE
  Future<void> updateIncident(String id, {String? status}) async {
    final incident = _box.get(id);
    if (incident == null) return;
    if (status != null) incident.status = status;
    await incident.save();
  }

  // DELETE
  Future<void> deleteIncident(String id) async {
    await _box.delete(id);
  }

  // DELETE ALL (used for testing persistence/reset)
  Future<void> clearAll() async {
    await _box.clear();
  }
}
