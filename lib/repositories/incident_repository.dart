import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/incident.dart';
import '../services/app_logger.dart';
import '../services/incident_api.dart';
import '../services/local_storage_service.dart';

/// Akses data insiden: Hive (sumber utama) dan, bila API diatur, backend.
class IncidentRepository {
  IncidentRepository([this._api]);

  static const boxName = LocalStorageService.incidentsBox;
  static const pendingDeletionsBoxName =
      LocalStorageService.pendingDeletionsBox;
  final IncidentApi? _api;

  Box<String> get _box => Hive.box<String>(boxName);

  Future<Box<String>> _getPendingDeletionsBox() async {
    if (!Hive.isBoxOpen(pendingDeletionsBoxName)) {
      return await Hive.openBox<String>(pendingDeletionsBoxName);
    }
    return Hive.box<String>(pendingDeletionsBoxName);
  }

  /// true jika API_BASE_URL diatur sehingga data bisa dimuat dari backend.
  bool get syncEnabled => _api != null;

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
        AppLogger.instance
            .warning('data', 'Melewati catatan insiden rusak', error);
      }
    }
    incidents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return incidents;
  }

  Future<Incident> addIncident(Incident incident) async {
    // Simpan lokal terlebih dahulu agar proses SMS darurat tidak tertunda (Fix #15).
    await _put(incident);
    // Kirim ke server di background tanpa ditunggu; kegagalan ditangani di _mirrorToServer.
    unawaited(
      _mirrorToServer('tambah insiden', (api) => api.createIncident(incident)),
    );
    return incident;
  }

  Future<void> updateIncident(Incident incident) async {
    await _put(incident);
    await _mirrorToServer(
        'ubah insiden', (api) => api.updateIncident(incident));
  }

  Future<void> deleteIncident(String id) async {
    await LocalStorageService.ensureReady();
    await _box.delete(id);
    final pendingBox = await _getPendingDeletionsBox();
    await pendingBox.put(id, id);
    if (_api != null) {
      try {
        await _api.deleteIncident(id);
        await pendingBox.delete(id);
      } catch (error) {
        AppLogger.instance
            .warning('sync', 'Sinkronisasi (hapus insiden) gagal', error);
      }
    }
  }

  /// Memuat insiden dari backend lalu menggabungkannya dengan data lokal.
  /// Perangkat adalah sumber utama: insiden yang hanya ada di server disimpan
  /// ke perangkat, sedangkan insiden yang belum ada di server (atau statusnya
  /// berbeda) dikirim ke server.
  /// Insiden yang telah dihapus di lokal tetapi belum terhapus di server (karena offline)
  /// tidak ditarik kembali (Bug #8 & #17), dan penghapusannya dikirim ulang ke server.
  Future<List<Incident>> syncFromServer() async {
    final api = _api;
    if (api == null) return getAllIncidents();
    await LocalStorageService.ensureReady();
    final pendingBox = await _getPendingDeletionsBox();

    // Pertahankan tombstone sampai GET membuktikan item tidak lagi ada pada
    // server. Server yang akhirnya konsisten tidak boleh menariknya kembali.
    final pendingIds = pendingBox.keys.cast<String>().toSet();
    for (final deletedId in pendingIds) {
      try {
        await api.deleteIncident(deletedId);
      } catch (error) {
        AppLogger.instance.warning(
          'sync',
          'Gagal mengirim ulang penghapusan insiden $deletedId ke server',
          error,
        );
      }
    }

    final remote = await api.getIncidents();
    final local = await getAllIncidents();

    // Baca ulang pendingIds tepat sebelum _pullMissing agar insiden yang baru
    // dihapus saat getIncidents() berjalan tidak ikut tertarik kembali (Fix #17).
    final latestPendingIds = {
      ...pendingIds,
      ...pendingBox.keys.cast<String>(),
    };

    await _pullMissing(remote, local, latestPendingIds);

    final remoteIds = {for (final incident in remote) incident.id};
    for (final deletedId in pendingIds) {
      if (!remoteIds.contains(deletedId)) await pendingBox.delete(deletedId);
    }

    await _pushDifferences(api, remote, local);
    AppLogger.instance.info(
      'sync',
      'Sinkronisasi selesai: ${remote.length} di server, ${local.length} di perangkat',
    );
    return getAllIncidents();
  }

  Future<void> _pullMissing(
    List<Incident> remote,
    List<Incident> local, [
    Set<String> pendingDeletions = const {},
  ]) async {
    final localIds = {for (final incident in local) incident.id};
    for (final incident in remote) {
      if (!localIds.contains(incident.id) &&
          !pendingDeletions.contains(incident.id)) {
        await _put(incident);
      }
    }
  }

  /// Berhenti pada kegagalan pertama agar tidak menunggu timeout berulang.
  Future<void> _pushDifferences(
    IncidentApi api,
    List<Incident> remote,
    List<Incident> local,
  ) async {
    final remoteById = {for (final incident in remote) incident.id: incident};
    try {
      for (final incident in local) {
        final onServer = remoteById[incident.id];
        if (onServer == null) {
          await api.createIncident(incident);
        } else if (onServer.status != incident.status) {
          await api.updateIncident(incident);
        }
      }
    } on IncidentApiException catch (error) {
      AppLogger.instance
          .warning('sync', 'Gagal mengunggah perubahan insiden', error);
    }
  }

  Future<void> _put(Incident incident) async {
    await LocalStorageService.ensureReady();
    final pendingBox = await _getPendingDeletionsBox();
    await pendingBox.delete(incident.id);
    await _box.put(incident.id, jsonEncode(incident.toJson()));
  }

  /// Sinkronisasi ke server bersifat opsional: kegagalan hanya dicatat.
  Future<void> _mirrorToServer(
    String action,
    Future<void> Function(IncidentApi api) call,
  ) async {
    final api = _api;
    if (api == null) return;
    try {
      await call(api);
    } catch (error) {
      AppLogger.instance.warning('sync', 'Sinkronisasi ($action) gagal', error);
    }
  }
}