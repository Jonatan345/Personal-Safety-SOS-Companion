import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sos_companion/models/emergency_contact.dart';
import 'package:sos_companion/repositories/emergency_contact_repository.dart';

void main() {
  late Directory testDirectory;

  setUp(() async {
    testDirectory =
        await Directory.systemTemp.createTemp('sos_contact_repository_test_');
    Hive.init(testDirectory.path);
    await Hive.openBox<String>(HiveEmergencyContactRepository.boxName);
  });

  tearDown(() async {
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  test('saved emergency contact remains available after reopening the box',
      () async {
    final repository = HiveEmergencyContactRepository();
    const draft = EmergencyContactDraft(
      name: 'Ibu Sari',
      phoneNumber: '08123456789',
    );

    await repository.saveContact(draft);
    await Hive.box<String>(HiveEmergencyContactRepository.boxName).close();
    await Hive.openBox<String>(HiveEmergencyContactRepository.boxName);

    final contact = await repository.fetchContact();

    expect(contact?.id, HiveEmergencyContactRepository.contactKey);
    expect(contact?.name, 'Ibu Sari');
    expect(contact?.phoneNumber, '08123456789');
  });
}
