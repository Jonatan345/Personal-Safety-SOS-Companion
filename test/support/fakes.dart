import 'dart:async';

import 'package:sos_companion/models/emergency_contact.dart';
import 'package:sos_companion/models/incident.dart';
import 'package:sos_companion/repositories/emergency_contact_repository.dart';
import 'package:sos_companion/repositories/incident_repository.dart';
import 'package:sos_companion/services/alert_service.dart';

/// Satu-satunya pembuat insiden uji, dipakai semua test.
Incident buildIncident({
  String id = '1',
  DateTime? timestamp,
  double? latitude,
  double? longitude,
  String status = 'sent',
}) {
  return Incident(
    id: id,
    timestamp: timestamp ?? DateTime(2026, 10, 15, 5),
    latitude: latitude,
    longitude: longitude,
    status: status,
  );
}

/// Insiden dengan lokasi nyata (Jakarta) dan status terkirim.
Incident buildLocatedIncident({String id = '1'}) => buildIncident(
      id: id,
      latitude: -6.2088,
      longitude: 106.8456,
    );

const testContact = EmergencyContact(
  id: 'primary-contact',
  name: 'Ibu Sari',
  phoneNumber: '081234567890',
);

/// Repository insiden dalam memori. Semua perilaku (gagal baca, gagal simpan,
/// sinkronisasi) diatur lewat parameter.
class FakeIncidentRepository extends IncidentRepository {
  FakeIncidentRepository({
    List<Incident> initial = const [],
    this.failFirstLoad = false,
    this.failAdd = false,
    this.failMutations = false,
    this.firstReadGate,
    this.onSync,
  }) : stored = List<Incident>.of(initial);

  final List<Incident> stored;
  final bool failFirstLoad;
  final bool failAdd;
  final bool failMutations;
  final Completer<void>? firstReadGate;
  final Future<List<Incident>> Function()? onSync;
  final List<Incident> updated = [];
  int loads = 0;

  @override
  bool get syncEnabled => onSync != null;

  @override
  Future<List<Incident>> getAllIncidents() async {
    loads++;
    if (failFirstLoad && loads == 1) throw StateError('gagal membaca');
    if (loads == 1) await firstReadGate?.future;
    return List<Incident>.of(stored);
  }

  @override
  Future<List<Incident>> syncFromServer() => onSync!();

  @override
  Future<Incident> addIncident(Incident incident) async {
    if (failAdd) throw StateError('disk penuh');
    stored.add(incident);
    return incident;
  }

  @override
  Future<void> updateIncident(Incident incident) async {
    if (failMutations) throw StateError('gagal memperbarui');
    updated.add(incident);
    final index = stored.indexWhere((item) => item.id == incident.id);
    if (index >= 0) stored[index] = incident;
  }

  @override
  Future<void> deleteIncident(String id) async {
    if (failMutations) throw StateError('gagal menghapus');
    stored.removeWhere((incident) => incident.id == id);
  }
}

/// Repository kontak darurat. [saveCalls] menghitung berapa kali API disimpan
/// dipanggil (untuk memastikan validasi dan tap ganda tidak membocor ke API).
class FakeEmergencyContactRepository implements EmergencyContactRepository {
  FakeEmergencyContactRepository({this.contact, this.onFetch, this.onSave});

  final EmergencyContact? contact;
  final Future<EmergencyContact?> Function()? onFetch;
  final Future<EmergencyContact> Function(EmergencyContactDraft draft)? onSave;
  int saveCalls = 0;

  @override
  Future<EmergencyContact?> fetchContact() =>
      onFetch?.call() ?? Future.value(contact);

  @override
  Future<EmergencyContact> saveContact(EmergencyContactDraft draft) {
    saveCalls++;
    return onSave?.call(draft) ??
        Future.value(EmergencyContact(
          id: '1',
          name: draft.name,
          phoneNumber: draft.phoneNumber,
        ));
  }
}

/// Alert palsu yang mencatat urutan panggilan di [events].
class FakeAlerts implements AlertGateway {
  FakeAlerts({this.notificationFailure, this.smsFailure});

  final String? notificationFailure;
  final String? smsFailure;
  final events = <String>[];
  final notifications = <String>[];
  final smsMessages = <String>[];
  final smsPhones = <String>[];

  @override
  Future<String?> showEmergencyNotification(String body) async {
    events.add('notification');
    notifications.add(body);
    return notificationFailure;
  }

  @override
  Future<String?> openSmsComposer({
    required String phone,
    required String message,
  }) async {
    events.add('sms');
    smsPhones.add(phone);
    smsMessages.add(message);
    return smsFailure;
  }
}
