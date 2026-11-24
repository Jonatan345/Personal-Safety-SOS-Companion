import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/emergency_contact.dart';
import '../services/local_storage_service.dart';

abstract class EmergencyContactRepository {
  Future<List<EmergencyContact>> fetchContacts();
  Future<EmergencyContact?> fetchContact();
  Future<EmergencyContact> saveContact(EmergencyContactDraft draft);
  Future<List<EmergencyContact>> saveContacts(List<EmergencyContact> contacts);
  Future<EmergencyContact> addContact(EmergencyContactDraft draft);
  Future<EmergencyContact> updateContact(EmergencyContact contact);
  Future<void> deleteContact(String id);
  Future<void> reorderContacts(int oldIndex, int newIndex);
}

class HiveEmergencyContactRepository implements EmergencyContactRepository {
  static const String boxName = LocalStorageService.contactsBox;
  static const String contactKey = 'primary-contact';
  static const String contactsListKey = 'emergency_contacts_list';
  static const int maxContacts = 5;

  Box<String> get _box => Hive.box<String>(boxName);

  @override
  Future<List<EmergencyContact>> fetchContacts() async {
    await LocalStorageService.ensureReady();
    final listJson = _box.get(contactsListKey);
    if (listJson != null) {
      final decoded = jsonDecode(listJson);
      if (decoded is List) {
        return decoded
            .map((e) =>
                EmergencyContact.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    }

    // Migrasi data kontak tunggal versi sebelumnya (Feature #11)
    final singleJson = _box.get(contactKey);
    if (singleJson != null) {
      final decoded = jsonDecode(singleJson);
      if (decoded is! Map<String, dynamic> && decoded is! Map) {
        throw const FormatException('Stored emergency contact is invalid.');
      }
      final singleContact = EmergencyContact.fromJson(
        Map<String, dynamic>.from(decoded as Map),
      );
      return [singleContact];
    }

    return [];
  }

  @override
  Future<EmergencyContact?> fetchContact() async {
    final contacts = await fetchContacts();
    return contacts.isEmpty ? null : contacts.first;
  }

  @override
  Future<EmergencyContact> saveContact(EmergencyContactDraft draft) async {
    await LocalStorageService.ensureReady();
    final contact = EmergencyContact(
      id: contactKey,
      name: draft.name,
      phoneNumber: draft.phoneNumber,
    );
    await _box.put(contactKey, jsonEncode(contact.toJson()));
    await _box.delete(contactsListKey);
    return contact;
  }

  @override
  Future<List<EmergencyContact>> saveContacts(
      List<EmergencyContact> contacts) async {
    await _saveList(contacts);
    return contacts;
  }

  @override
  Future<EmergencyContact> addContact(EmergencyContactDraft draft) async {
    final contacts = await fetchContacts();
    if (contacts.length >= maxContacts) {
      throw StateError('Maksimal $maxContacts kontak darurat tercapai.');
    }
    final contact = EmergencyContact(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: draft.name,
      phoneNumber: draft.phoneNumber,
    );
    contacts.add(contact);
    await _saveList(contacts);
    return contact;
  }

  @override
  Future<EmergencyContact> updateContact(EmergencyContact contact) async {
    final contacts = await fetchContacts();
    final index = contacts.indexWhere((c) => c.id == contact.id);
    if (index >= 0) {
      contacts[index] = contact;
      await _saveList(contacts);
    }
    return contact;
  }

  @override
  Future<void> deleteContact(String id) async {
    final contacts = await fetchContacts();
    contacts.removeWhere((c) => c.id == id);
    await _saveList(contacts);
  }

  @override
  Future<void> reorderContacts(int oldIndex, int newIndex) async {
    final contacts = await fetchContacts();
    if (oldIndex < 0 ||
        oldIndex >= contacts.length ||
        newIndex < 0 ||
        newIndex > contacts.length) {
      return;
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = contacts.removeAt(oldIndex);
    contacts.insert(newIndex, item);
    await _saveList(contacts);
  }

  Future<void> _saveList(List<EmergencyContact> contacts) async {
    await LocalStorageService.ensureReady();
    await _box.put(
      contactsListKey,
      jsonEncode(contacts.map((c) => c.toJson()).toList()),
    );
    if (contacts.isNotEmpty) {
      await _box.put(contactKey, jsonEncode(contacts.first.toJson()));
    } else {
      await _box.delete(contactKey);
    }
  }
}

final emergencyContactRepositoryProvider = Provider<EmergencyContactRepository>(
  (ref) => HiveEmergencyContactRepository(),
);
