import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_contact.dart';
import '../repositories/emergency_contact_repository.dart';

class LoadEmergencyContactUseCase {
  const LoadEmergencyContactUseCase(this._repository);

  final EmergencyContactRepository _repository;

  Future<EmergencyContact?> call() => _repository.fetchContact();
}

class SaveEmergencyContactUseCase {
  const SaveEmergencyContactUseCase(this._repository);

  final EmergencyContactRepository _repository;

  Future<EmergencyContact> call(EmergencyContactDraft draft) =>
      _repository.saveContact(draft);
}

final loadEmergencyContactUseCaseProvider =
    Provider<LoadEmergencyContactUseCase>(
  (ref) => LoadEmergencyContactUseCase(
      ref.watch(emergencyContactRepositoryProvider)),
);

final saveEmergencyContactUseCaseProvider =
    Provider<SaveEmergencyContactUseCase>(
  (ref) => SaveEmergencyContactUseCase(
      ref.watch(emergencyContactRepositoryProvider)),
);
