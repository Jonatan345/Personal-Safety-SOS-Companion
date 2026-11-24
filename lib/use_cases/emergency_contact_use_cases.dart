import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_contact.dart';
import '../repositories/emergency_contact_repository.dart';

class LoadEmergencyContactUseCase {
  const LoadEmergencyContactUseCase(this._repository);

  final EmergencyContactRepository _repository;

  Future<List<EmergencyContact>> call() => _repository.fetchContacts();
}

class SaveEmergencyContactUseCase {
  const SaveEmergencyContactUseCase(this._repository);

  final EmergencyContactRepository _repository;

  Future<EmergencyContact> call(EmergencyContactDraft draft) =>
      _repository.saveContact(draft);
}

class AddEmergencyContactUseCase {
  const AddEmergencyContactUseCase(this._repository);

  final EmergencyContactRepository _repository;

  Future<EmergencyContact> call(EmergencyContactDraft draft) =>
      _repository.addContact(draft);
}

class UpdateEmergencyContactUseCase {
  const UpdateEmergencyContactUseCase(this._repository);

  final EmergencyContactRepository _repository;

  Future<EmergencyContact> call(EmergencyContact contact) =>
      _repository.updateContact(contact);
}

class DeleteEmergencyContactUseCase {
  const DeleteEmergencyContactUseCase(this._repository);

  final EmergencyContactRepository _repository;

  Future<void> call(String id) => _repository.deleteContact(id);
}

class ReorderEmergencyContactsUseCase {
  const ReorderEmergencyContactsUseCase(this._repository);

  final EmergencyContactRepository _repository;

  Future<void> call(int oldIndex, int newIndex) =>
      _repository.reorderContacts(oldIndex, newIndex);
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

final addEmergencyContactUseCaseProvider =
    Provider<AddEmergencyContactUseCase>(
  (ref) => AddEmergencyContactUseCase(
      ref.watch(emergencyContactRepositoryProvider)),
);

final updateEmergencyContactUseCaseProvider =
    Provider<UpdateEmergencyContactUseCase>(
  (ref) => UpdateEmergencyContactUseCase(
      ref.watch(emergencyContactRepositoryProvider)),
);

final deleteEmergencyContactUseCaseProvider =
    Provider<DeleteEmergencyContactUseCase>(
  (ref) => DeleteEmergencyContactUseCase(
      ref.watch(emergencyContactRepositoryProvider)),
);

final reorderEmergencyContactsUseCaseProvider =
    Provider<ReorderEmergencyContactsUseCase>(
  (ref) => ReorderEmergencyContactsUseCase(
      ref.watch(emergencyContactRepositoryProvider)),
);
