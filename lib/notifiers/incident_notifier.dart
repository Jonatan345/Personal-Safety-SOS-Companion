import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/incident.dart';
import '../repositories/incident_repository.dart';
import '../services/incident_api.dart';

class IncidentNotifier extends StateNotifier<AsyncValue<List<Incident>>> {
  final IncidentRepository _repository;

  IncidentNotifier(this._repository) : super(const AsyncLoading()) {
    unawaited(refresh());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _repository.getAllIncidents());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> addIncident(Incident incident) async {
    final previous = state;
    try {
      final created = await _repository.addIncident(incident);
      final incidents = previous.asData?.value ?? const <Incident>[];
      state = AsyncData(_sorted([created, ...incidents]));
    } catch (error, stackTrace) {
      final incidents = previous.asData?.value;
      state = incidents == null
          ? AsyncError(error, stackTrace)
          : AsyncData(List<Incident>.of(incidents));
      rethrow;
    }
  }

  Future<void> updateStatus(String id, String status) async {
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
      state = AsyncData(updated);
    } catch (_) {
      state = AsyncData(List<Incident>.of(incidents));
      rethrow;
    }
  }

  Future<void> deleteIncident(String id) async {
    final previous = state;
    final incidents = previous.asData?.value;
    if (incidents == null) return;
    try {
      await _repository.deleteIncident(id);
      state = AsyncData(incidents.where((incident) => incident.id != id).toList());
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
  return IncidentApi(
    baseUrl: const String.fromEnvironment('API_BASE_URL'),
    client: client,
  );
});

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository(ref.watch(incidentApiProvider));
});

final incidentNotifierProvider = StateNotifierProvider<IncidentNotifier,
    AsyncValue<List<Incident>>>((ref) {
  final repository = ref.watch(incidentRepositoryProvider);
  return IncidentNotifier(repository);
});
