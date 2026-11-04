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
}
