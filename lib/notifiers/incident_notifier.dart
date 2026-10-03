import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/incident.dart';
import '../repositories/incident_repository.dart';

/// LOCAL DATA & PERSISTENCE (P5) — STATE LAYER (Riverpod)
/// Exposes incident list as state; UI reacts via ref.watch().
class IncidentNotifier extends StateNotifier<List<Incident>> {
  final IncidentRepository _repository;

  IncidentNotifier(this._repository) : super(const []) {
    _loadInitial();
  }

  void _loadInitial() {
    state = _repository.getAllIncidents();
  }

  // CREATE
  Future<void> addIncident(Incident incident) async {
    await _repository.addIncident(incident);
    state = _repository.getAllIncidents();
  }

  // READ (manual refresh, e.g. pull-to-refresh)
  void refresh() {
    state = _repository.getAllIncidents();
  }

  // UPDATE
  Future<void> updateStatus(String id, String status) async {
    await _repository.updateIncidentStatus(id, status);
    state = _repository.getAllIncidents();
  }

  // DELETE
  Future<void> deleteIncident(String id) async {
    await _repository.deleteIncident(id);
    state = _repository.getAllIncidents();
  }
}

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository();
});

final incidentNotifierProvider =
    StateNotifierProvider<IncidentNotifier, List<Incident>>((ref) {
  final repository = ref.watch(incidentRepositoryProvider);
  return IncidentNotifier(repository);
});
