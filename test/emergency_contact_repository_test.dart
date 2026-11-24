import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sos_companion/models/emergency_contact.dart';
import 'package:sos_companion/repositories/emergency_contact_repository.dart';

void main() {
  late Directory testDirectory;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'sos_contact_repository_test_',
    );
    Hive.init(testDirectory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async => testDirectory.path,
    );
    await Hive.openBox<String>(HiveEmergencyContactRepository.boxName);
  });

  tearDown(() async {
    await Hive.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await testDirectory.delete(recursive: true);
  });

  test('returns null when no contact has been saved', () async {
    expect(await HiveEmergencyContactRepository().fetchContact(), isNull);
  });

  test('persists the contact after the box is closed and reopened', () async {
    final repository = HiveEmergencyContactRepository();
    await repository.saveContact(
      const EmergencyContactDraft(name: 'Ibu Sari', phoneNumber: '911'),
    );

    await Hive.box<String>(HiveEmergencyContactRepository.boxName).close();
    await Hive.openBox<String>(HiveEmergencyContactRepository.boxName);

    final contact = await repository.fetchContact();
    expect(contact?.name, 'Ibu Sari');
    expect(contact?.phoneNumber, '911');
  });

  test('saving again replaces the single contact', () async {
    final repository = HiveEmergencyContactRepository();
    await repository.saveContact(
      const EmergencyContactDraft(name: 'Ibu Sari', phoneNumber: '911'),
    );
    await repository.saveContact(
      const EmergencyContactDraft(name: 'Pak Budi', phoneNumber: '112'),
    );

    final contact = await repository.fetchContact();
    expect(contact?.name, 'Pak Budi');
    expect(contact?.phoneNumber, '112');
    expect(
      Hive.box<String>(HiveEmergencyContactRepository.boxName).length,
      1,
    );
  });

  test('a stored contact that is not valid JSON is reported', () async {
    await Hive.box<String>(HiveEmergencyContactRepository.boxName)
        .put(HiveEmergencyContactRepository.contactKey, '{bukan-json');

    await expectLater(
      HiveEmergencyContactRepository().fetchContact(),
      throwsFormatException,
    );
  });

  test('a stored contact with missing fields is reported', () async {
    await Hive.box<String>(HiveEmergencyContactRepository.boxName)
        .put(HiveEmergencyContactRepository.contactKey, '{"id":"x"}');

    await expectLater(
      HiveEmergencyContactRepository().fetchContact(),
      throwsFormatException,
    );
  });

  test('toJson and fromJson round-trip a contact', () {
    const contact = EmergencyContact(
      id: 'primary-contact',
      name: 'Ibu Sari',
      phoneNumber: '081234567890',
    );

    final restored = EmergencyContact.fromJson(contact.toJson());

    expect(restored.id, contact.id);
    expect(restored.name, contact.name);
    expect(restored.phoneNumber, contact.phoneNumber);
  });

  group('dukungan beberapa kontak (Feature #11)', () {
    test('bisa menambah hingga 5 kontak dengan urutan prioritas', () async {
      final repository = HiveEmergencyContactRepository();
      for (var i = 1; i <= 5; i++) {
        await repository.addContact(
          EmergencyContactDraft(name: 'Kontak $i', phoneNumber: '0812$i'),
        );
      }

      final contacts = await repository.fetchContacts();
      expect(contacts.length, 5);
      expect(contacts.first.name, 'Kontak 1');
      expect(contacts.last.name, 'Kontak 5');

      // Kontak ke-6 melebihi batas maksimal 5
      await expectLater(
        repository.addContact(
          const EmergencyContactDraft(name: 'Kontak 6', phoneNumber: '08126'),
        ),
        throwsStateError,
      );
    });

    test('bisa mengubah urutan kontak (reorder)', () async {
      final repository = HiveEmergencyContactRepository();
      await repository.addContact(
        const EmergencyContactDraft(name: 'Kontak A', phoneNumber: '0811'),
      );
      await repository.addContact(
        const EmergencyContactDraft(name: 'Kontak B', phoneNumber: '0812'),
      );

      await repository.reorderContacts(1, 0);

      final contacts = await repository.fetchContacts();
      expect(contacts[0].name, 'Kontak B');
      expect(contacts[1].name, 'Kontak A');
    });

    test('bisa memperbarui dan menghapus kontak', () async {
      final repository = HiveEmergencyContactRepository();
      final c1 = await repository.addContact(
        const EmergencyContactDraft(name: 'Kontak A', phoneNumber: '0811'),
      );
      await repository.addContact(
        const EmergencyContactDraft(name: 'Kontak B', phoneNumber: '0812'),
      );

      await repository.updateContact(
        EmergencyContact(id: c1.id, name: 'Kontak A Edit', phoneNumber: '0819'),
      );
      var contacts = await repository.fetchContacts();
      expect(contacts.first.name, 'Kontak A Edit');
      expect(contacts.first.phoneNumber, '0819');

      await repository.deleteContact(c1.id);
      contacts = await repository.fetchContacts();
      expect(contacts.length, 1);
      expect(contacts.first.name, 'Kontak B');
    });
  });
}
