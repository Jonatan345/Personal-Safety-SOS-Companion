import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/emergency_contact.dart';
import '../services/local_storage_service.dart';

abstract class EmergencyContactRepository {
  Future<EmergencyContact?> fetchContact();
  Future<EmergencyContact> saveContact(EmergencyContactDraft draft);
}

class HiveEmergencyContactRepository implements EmergencyContactRepository {
  // Versioned namespace avoids reading incompatible Hive data from older demos.
  static const String boxName = 'emergency_contacts_v2';
  static const String contactKey = 'primary-contact';

  Box<String> get _box => Hive.box<String>(boxName);

  @override
  Future<EmergencyContact?> fetchContact() async {
    await LocalStorageService.ensureReady();
    final serializedContact = _box.get(contactKey);
    if (serializedContact == null) return null;

    final decoded = jsonDecode(serializedContact);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Stored emergency contact is invalid.');
    }

    final id = decoded['id'];
    final name = decoded['name'];
    final phoneNumber = decoded['phoneNumber'];
    if (id is! String || name is! String || phoneNumber is! String) {
      throw const FormatException('Stored emergency contact is incomplete.');
    }

    return EmergencyContact(id: id, name: name, phoneNumber: phoneNumber);
  }

  @override
  Future<EmergencyContact> saveContact(EmergencyContactDraft draft) async {
    await LocalStorageService.ensureReady();
    final contact = EmergencyContact(
      id: contactKey,
      name: draft.name,
      phoneNumber: draft.phoneNumber,
    );
    await _box.put(
      contactKey,
      jsonEncode({
        'id': contact.id,
        'name': contact.name,
        'phoneNumber': contact.phoneNumber,
      }),
    );
    return contact;
  }
}

final emergencyContactRepositoryProvider = Provider<EmergencyContactRepository>(
  (ref) => HiveEmergencyContactRepository(),
);
