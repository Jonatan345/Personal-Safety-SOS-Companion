import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/incident.dart';
import '../services/incident_api.dart';
import '../services/local_storage_service.dart';

class IncidentRepository {
  IncidentRepository([this._api]);
  static const boxName = LocalStorageService.incidentsBox;
  final IncidentApi? _api;

  Box<String> get _box => Hive.box<String>(boxName);

  /// true jika API_BASE_URL diatur sehingga data bisa dimuat dari backend.
  bool get syncEnabled => _api != null;

  /// Memuat insiden dari backend lalu menggabungkannya dengan data lokal:
  /// insiden yang hanya ada di server disimpan ke perangkat, dan insiden yang
  /// hanya ada di perangkat dikirim ke server (best effort). Melempar
  /// [IncidentApiException] (dengan `userMessage` Bahasa Indonesia) jika server
  /// tidak dapat dihubungi; data lokal tidak berubah pada kegagalan.
  /// Catatan: penghapusan yang gagal dikirim ke server dapat muncul kembali.
  Future<List<Incident>> syncFromServer() async {
    final api = _api;
    if (api == null) return getAllIncidents();
    await LocalStorageService.ensureReady();

    final remote = await api.getIncidents();
    final local = await getAllIncidents();
    final localIds = {for (final incident in local) incident.id};
    for (final incident in remote) {
      if (!localIds.contains(incident.id)) {
        await _box.put(incident.id, jsonEncode(incident.toJson()));
      }
    }

    final remoteIds = {for (final incident in remote) incident.id};
    for (final incident in local) {
      if (remoteIds.contains(incident.id)) continue;
      try {
        await api.createIncident(incident);
      } on IncidentApiException catch (error) {
        debugPrint('Gagal mengunggah insiden ${incident.id}: $error');
        break;
      }
    }
    return getAllIncidents();
  }

  Future<List<Incident>> getAllIncidents() async {
    await LocalStorageService.ensureReady();
    final incidents = <Incident>[];
    for (final value in _box.values) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          incidents.add(Incident.fromJson(decoded));
        }
      } on FormatException catch (error) {
        // Satu catatan rusak tidak boleh menggagalkan seluruh riwayat.
        debugPrint('Melewati catatan insiden rusak: $error');
      }
    }
    incidents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return incidents;
  }

  Future<Incident> addIncident(Incident incident) async {
    await LocalStorageService.ensureReady();
    await _box.put(incident.id, jsonEncode(incident.toJson()));
    // Server sync remains optional for the P6 demo backend; local history is authoritative.
    if (_api != null) {
      try {
        await _api.createIncident(incident);
      } catch (error) {
        debugPrint('Sinkronisasi insiden ke server gagal: $error');
      }
    }
    return incident;
  }

  Future<void> updateIncident(Incident incident) async {
    await LocalStorageService.ensureReady();
    await _box.put(incident.id, jsonEncode(incident.toJson()));
    if (_api != null) {
      try {
        await _api.updateIncident(incident);
      } catch (error) {
        debugPrint('Sinkronisasi pembaruan insiden gagal: $error');
      }
    }
  }

  Future<void> deleteIncident(String id) async {
    await LocalStorageService.ensureReady();
    await _box.delete(id);
    if (_api != null) {
      try {
        await _api.deleteIncident(id);
      } catch (error) {
        debugPrint('Sinkronisasi penghapusan insiden gagal: $error');
      }
    }
  }
}
