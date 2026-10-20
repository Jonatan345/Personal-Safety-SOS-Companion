import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/incident.dart';
import '../repositories/incident_repository.dart';
import '../services/incident_api.dart';

class IncidentNotifier extends StateNotifier<AsyncValue<List<Incident>>> {
  final IncidentRepository _repository;
  int _operation = 0;

  IncidentNotifier(this._repository) : super(const AsyncLoading()) {
    unawaited(refresh());
  }

  Future<void> refresh() async {
    final operation = ++_operation;
    state = const AsyncLoading();
    try {
      final incidents = await _repository.getAllIncidents();
      if (operation == _operation) state = AsyncData(incidents);
    } catch (error, stackTrace) {
      if (operation == _operation) state = AsyncError(error, stackTrace);
    }
  }

  Future<void> addIncident(Incident incident) async {
    final operation = ++_operation;
    final previous = state;
    try {
      final created = await _repository.addIncident(incident);
      final incidents = previous.asData?.value ?? const <Incident>[];
      if (operation == _operation) {
        state = AsyncData(_sorted([created, ...incidents]));
      }
    } catch (error, stackTrace) {
      final incidents = previous.asData?.value;
      state = incidents == null
          ? AsyncError(error, stackTrace)
          : AsyncData(List<Incident>.of(incidents));
      rethrow;
    }
  }

  Future<void> updateStatus(String id, String status) async {
    final operation = ++_operation;
    final previous = state;
    final incidents = previous.asData?.value;
    if (incidents == null) return;
    final updated = incidents
        .map((incident) => incident.id == id
            ? Incident(
                id: incident.id,
                timestamp: incident.timestamp,
                latitude: incident.latitude,
                longitude: incident.longitude,
                status: status,
              )
            : incident)
        .toList();

    try {
      final incident = updated.firstWhere((item) => item.id == id);
      await _repository.updateIncident(incident);
      if (operation == _operation) state = AsyncData(updated);
    } catch (_) {
      state = AsyncData(List<Incident>.of(incidents));
      rethrow;
    }
  }

  Future<void> deleteIncident(String id) async {
    final operation = ++_operation;
    final previous = state;
    final incidents = previous.asData?.value;
    if (incidents == null) return;
    try {
      await _repository.deleteIncident(id);
      if (operation == _operation) {
        state = AsyncData(incidents.where((incident) => incident.id != id).toList());
      }
    } catch (_) {
      state = AsyncData(List<Incident>.of(incidents));
      rethrow;
    }
  }

  List<Incident> _sorted(List<Incident> incidents) {
    return incidents..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}

final incidentApiProvider = Provider<IncidentApi>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  return IncidentApi(
    baseUrl: configuredBaseUrl.isNotEmpty
        ? configuredBaseUrl
        : 'http://10.0.2.2:8080/api',
    client: client,
  );
});

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository();
});

final incidentNotifierProvider =
    StateNotifierProvider<IncidentNotifier, AsyncValue<List<Incident>>>((ref) {
  final repository = ref.watch(incidentRepositoryProvider);
  return IncidentNotifier(repository);
});
