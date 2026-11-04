import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/incident.dart';
import '../repositories/incident_repository.dart';
import '../services/incident_api.dart';
import '../utils/error_messages.dart';

enum IncidentSyncPhase { idle, syncing, failed }

/// Status sinkronisasi dengan backend (hanya relevan jika API_BASE_URL diatur).
class IncidentSyncState {
  const IncidentSyncState._(this.phase, this.message);
  const IncidentSyncState.idle() : this._(IncidentSyncPhase.idle, null);
  const IncidentSyncState.syncing() : this._(IncidentSyncPhase.syncing, null);
  const IncidentSyncState.failed(String message)
      : this._(IncidentSyncPhase.failed, message);

  final IncidentSyncPhase phase;
  final String? message;
}

class IncidentNotifier extends StateNotifier<AsyncValue<List<Incident>>> {
  final IncidentRepository _repository;
  final void Function(IncidentSyncState state)? _onSyncChanged;
  int _operation = 0;

  IncidentNotifier(
    this._repository, {
    void Function(IncidentSyncState state)? onSyncChanged,
  })  : _onSyncChanged = onSyncChanged,
        super(const AsyncLoading()) {
    unawaited(refresh());
  }

  /// Memuat data lokal lebih dulu (cepat, tidak butuh jaringan), lalu
  /// menyinkronkan dengan backend bila tersedia.
  Future<void> refresh() async {
    final operation = ++_operation;
    state = const AsyncLoading();
    try {
      final incidents = await _repository.getAllIncidents();
      if (operation != _operation) return;
      state = AsyncData(incidents);
    } catch (error, stackTrace) {
      if (operation == _operation) state = AsyncError(error, stackTrace);
      return;
    }
    await _syncWithServer(operation);
  }

  Future<void> _syncWithServer(int operation) async {
    if (!_repository.syncEnabled) return;
    _emit(const IncidentSyncState.syncing());
    try {
      final merged = await _repository.syncFromServer();
      if (operation != _operation) return;
      state = AsyncData(merged);
      _emit(const IncidentSyncState.idle());
    } catch (error) {
      if (operation != _operation) return;
      _emit(IncidentSyncState.failed(userMessageFor(error)));
    }
  }

  void _emit(IncidentSyncState value) {
    if (mounted) _onSyncChanged?.call(value);
  }

  Future<void> addIncident(Incident incident) async {
    final operation = _beginMutation();
    final previous = state;
    try {
      final created = await _repository.addIncident(incident);
      // Baca ulang dari penyimpanan. Jika riwayat belum selesai dimuat saat
      // insiden ditambahkan, daftar lama tidak boleh hilang dari tampilan.
      List<Incident> incidents;
      try {
        incidents = await _repository.getAllIncidents();
      } catch (_) {
        incidents =
            _sorted([created, ...previous.asData?.value ?? const <Incident>[]]);
      }
      if (operation == _operation) state = AsyncData(incidents);
    } catch (error, stackTrace) {
      final incidents = previous.asData?.value;
      state = incidents == null
          ? AsyncError(error, stackTrace)
          : AsyncData(List<Incident>.of(incidents));
      rethrow;
    }
  }

  Future<void> updateStatus(String id, String status) {
    return _mutateExisting((incidents) async {
      final updated = incidents
          .map((incident) =>
              incident.id == id ? incident.copyWith(status: status) : incident)
          .toList();
      final target = updated.where((incident) => incident.id == id);
      if (target.isEmpty) return incidents;
      await _repository.updateIncident(target.first);
      return updated;
    });
  }

  Future<void> deleteIncident(String id) {
    return _mutateExisting((incidents) async {
      await _repository.deleteIncident(id);
      return incidents.where((incident) => incident.id != id).toList();
    });
  }

  /// Pola bersama untuk ubah/hapus: jalankan [action] pada daftar saat ini,
  /// pakai hasilnya sebagai state baru, dan pulihkan daftar lama bila gagal.
  Future<void> _mutateExisting(
    Future<List<Incident>> Function(List<Incident> current) action,
  ) async {
    final operation = _beginMutation();
    final incidents = state.asData?.value;
    if (incidents == null) return;
    try {
      final next = await action(incidents);
      if (operation == _operation) state = AsyncData(next);
    } catch (_) {
      state = AsyncData(List<Incident>.of(incidents));
      rethrow;
    }
  }

  /// Perubahan data membatalkan sinkronisasi yang sedang berjalan.
  int _beginMutation() {
    final operation = ++_operation;
    if (_repository.syncEnabled) _emit(const IncidentSyncState.idle());
    return operation;
  }

  List<Incident> _sorted(List<Incident> incidents) {
    return incidents..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}

final incidentApiProvider = Provider<IncidentApi?>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  // Location history is local-only unless the operator explicitly opts into a
  // separately secured HTTPS service at build time.
  if (configuredBaseUrl.isEmpty) return null;
  return IncidentApi(baseUrl: configuredBaseUrl, client: client);
});

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository(ref.watch(incidentApiProvider));
});

final incidentSyncProvider = StateProvider<IncidentSyncState>(
  (ref) => const IncidentSyncState.idle(),
);

final incidentNotifierProvider =
    StateNotifierProvider<IncidentNotifier, AsyncValue<List<Incident>>>((ref) {
  final repository = ref.watch(incidentRepositoryProvider);
  return IncidentNotifier(
    repository,
    onSyncChanged: (value) =>
        ref.read(incidentSyncProvider.notifier).state = value,
  );
});
