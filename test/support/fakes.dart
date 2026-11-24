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
    this.saveGate,
    this.onSync,
  }) : stored = List<Incident>.of(initial);

  final List<Incident> stored;
  final bool failFirstLoad;
  final bool failAdd;
  final bool failMutations;
  final Completer<void>? firstReadGate;
  final Completer<void>? saveGate;
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
    if (saveGate != null) await saveGate!.future;
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
  FakeEmergencyContactRepository({
    this.contact,
    List<EmergencyContact>? contacts,
    this.onFetch,
    this.onSave,
  }) : _contacts = contacts != null
            ? List<EmergencyContact>.of(contacts)
            : (contact != null ? [contact] : <EmergencyContact>[]);

  final EmergencyContact? contact;
  final List<EmergencyContact> _contacts;
  final Future<EmergencyContact?> Function()? onFetch;
  final Future<EmergencyContact> Function(EmergencyContactDraft draft)? onSave;
  int saveCalls = 0;

  @override
  Future<EmergencyContact?> fetchContact() {
    if (onFetch != null) return onFetch!();
    return Future.value(_contacts.isEmpty ? null : _contacts.first);
  }

  @override
  Future<List<EmergencyContact>> fetchContacts() async {
    if (onFetch != null) {
      final single = await onFetch!();
      return single != null ? [single] : [];
    }
    return List<EmergencyContact>.of(_contacts);
  }

  @override
  Future<EmergencyContact> saveContact(EmergencyContactDraft draft) =>
      _save(draft, id: '1', replaceAll: true);

  Future<EmergencyContact> _save(
    EmergencyContactDraft draft, {
    required String id,
    required bool replaceAll,
  }) async {
    saveCalls++;
    final created = onSave != null
        ? await onSave!(draft)
        : EmergencyContact(
            id: id, name: draft.name, phoneNumber: draft.phoneNumber);
    if (replaceAll) _contacts.clear();
    _contacts.removeWhere((contact) => contact.id == created.id);
    _contacts.add(created);
    return created;
  }

  @override
  Future<List<EmergencyContact>> saveContacts(
      List<EmergencyContact> contacts) async {
    _contacts.clear();
    _contacts.addAll(contacts);
    return List<EmergencyContact>.of(_contacts);
  }

  @override
  Future<EmergencyContact> addContact(EmergencyContactDraft draft) async {
    return _save(
      draft,
      id: (_contacts.length + 1).toString(),
      replaceAll: false,
    );
  }

  @override
  Future<EmergencyContact> updateContact(EmergencyContact contact) async {
    return _save(
      EmergencyContactDraft(
          name: contact.name, phoneNumber: contact.phoneNumber),
      id: contact.id,
      replaceAll: false,
    );
  }

  @override
  Future<void> deleteContact(String id) async {
    _contacts.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> reorderContacts(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _contacts.removeAt(oldIndex);
    _contacts.insert(newIndex, item);
  }
}

/// Alert palsu yang mencatat urutan panggilan di [events].
class FakeAlerts implements AlertGateway {
  FakeAlerts({this.notificationFailure, this.smsFailure});

  final String? notificationFailure;
  final String? smsFailure;
  final events = <String>[];
  final notifications = <String>[];
  final notificationIds = <int?>[];
  final smsMessages = <String>[];
  final smsPhones = <String>[];

  @override
  Future<String?> showEmergencyNotification(
    String body, {
    int? id,
    String? title,
  }) async {
    events.add('notification');
    notifications.add(body);
    notificationIds.add(id);
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
