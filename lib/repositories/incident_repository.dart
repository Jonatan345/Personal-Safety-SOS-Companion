import '../models/incident.dart';
import '../services/incident_api.dart';

class IncidentRepository {
  final IncidentApi _api;

  IncidentRepository(this._api);

  Future<List<Incident>> getAllIncidents() => _api.getIncidents();

  Future<Incident> addIncident(Incident incident) =>
      _api.createIncident(incident);

  Future<void> updateIncident(Incident incident) =>
      _api.updateIncident(incident);

  Future<void> deleteIncident(String id) => _api.deleteIncident(id);
}
