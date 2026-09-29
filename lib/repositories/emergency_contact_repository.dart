import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_contact.dart';

abstract class EmergencyContactRepository {
  Future<EmergencyContact?> fetchContact();
  Future<EmergencyContact> saveContact(EmergencyContactDraft draft);
}

/// Temporary P4 repository. Replace this with a Hive-backed implementation in P5.
class InMemoryEmergencyContactRepository implements EmergencyContactRepository {
  InMemoryEmergencyContactRepository(
      {this.latency = const Duration(milliseconds: 500)});

  final Duration latency;
  EmergencyContact? _contact;

  @override
  Future<EmergencyContact?> fetchContact() async {
    await Future<void>.delayed(latency);
    return _contact;
  }

  @override
  Future<EmergencyContact> saveContact(EmergencyContactDraft draft) async {
    await Future<void>.delayed(latency);
    _contact = EmergencyContact(
      id: 'primary-contact',
      name: draft.name,
      phoneNumber: draft.phoneNumber,
    );
    return _contact!;
  }
}

final emergencyContactRepositoryProvider = Provider<EmergencyContactRepository>(
  (ref) => InMemoryEmergencyContactRepository(),
);
