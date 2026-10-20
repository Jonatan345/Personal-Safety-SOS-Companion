import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/incident.dart';
import '../services/incident_api.dart';
import '../services/local_storage_service.dart';

class IncidentRepository {
  IncidentRepository([this._api]);
  // Versioned namespace avoids reading incompatible Hive data from older demos.
  static const boxName = 'incidents_v2';
  final IncidentApi? _api;

  Box<String> get _box => Hive.box<String>(boxName);

  Future<List<Incident>> getAllIncidents() async {
    await LocalStorageService.ensureReady();
    final incidents = <Incident>[];
    for (final value in _box.values) {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) incidents.add(Incident.fromJson(decoded));
    }
    incidents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return incidents;
  }

  Future<Incident> addIncident(Incident incident) async {
    await LocalStorageService.ensureReady();
    await _box.put(incident.id, jsonEncode(incident.toJson()));
    // Server sync remains optional for the P6 demo backend; local history is authoritative.
    if (_api != null) {
      try { await _api.createIncident(incident); } catch (_) {}
    }
    return incident;
  }

  Future<void> updateIncident(Incident incident) async {
    await LocalStorageService.ensureReady();
    await _box.put(incident.id, jsonEncode(incident.toJson()));
    if (_api != null) {
      try { await _api.updateIncident(incident); } catch (_) {}
    }
  }

  Future<void> deleteIncident(String id) async {
    await LocalStorageService.ensureReady();
    await _box.delete(id);
    if (_api != null) {
      try { await _api.deleteIncident(id); } catch (_) {}
    }
  }
}
