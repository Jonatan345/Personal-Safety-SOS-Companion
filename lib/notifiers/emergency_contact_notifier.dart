import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_contact.dart';
import '../use_cases/emergency_contact_use_cases.dart';

class EmergencyContactViewState {
  const EmergencyContactViewState({
    this.contacts = const [],
    EmergencyContact? contact,
    this.isSubmitting = false,
    this.submitError,
  }) : _contact = contact;

  final List<EmergencyContact> contacts;
  final EmergencyContact? _contact;
  final bool isSubmitting;
  final String? submitError;

  EmergencyContact? get contact => _contact ?? contacts.firstOrNull;
  bool get hasContact => contacts.isNotEmpty || _contact != null;
  int get contactCount => contacts.isNotEmpty ? contacts.length : (_contact != null ? 1 : 0);

  EmergencyContactViewState copyWith({
    List<EmergencyContact>? contacts,
    EmergencyContact? contact,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return EmergencyContactViewState(
      contacts: contacts ?? this.contacts,
      contact: contact ?? (contacts == null ? _contact : null),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : submitError ?? this.submitError,
    );
  }
}

/// Hasil satu kali simpan. Layar memakai nilai ini (bukan menebak dari state)
/// untuk memilih pesan: `alreadySaving` berarti tap ganda yang diabaikan.
enum ContactSaveResult { saved, failed, alreadySaving }

class EmergencyContactNotifier
    extends AsyncNotifier<EmergencyContactViewState> {
  static const saveFailureMessage = 'Kontak gagal disimpan. Silakan coba lagi.';
  static const maxContactsReachedMessage =
      'Maksimal 5 kontak darurat sudah tercapai.';

  @override
  Future<EmergencyContactViewState> build() => _loadContacts();

  Future<EmergencyContactViewState> _loadContacts() async {
    final contacts = await ref.read(loadEmergencyContactUseCaseProvider)();
    return EmergencyContactViewState(contacts: contacts);
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadContacts);
  }

  Future<ContactSaveResult> save(
    EmergencyContactDraft draft, {
    String? editId,
  }) async {
    final current = state.valueOrNull ?? const EmergencyContactViewState();
    if (current.isSubmitting) return ContactSaveResult.alreadySaving;

    state =
        AsyncData(current.copyWith(isSubmitting: true, clearSubmitError: true));

    try {
      if (editId != null) {
        await ref.read(updateEmergencyContactUseCaseProvider)(
          EmergencyContact(
            id: editId,
            name: draft.name,
            phoneNumber: draft.phoneNumber,
          ),
        );
      } else {
        if (current.contacts.isEmpty) {
          await ref.read(saveEmergencyContactUseCaseProvider)(draft);
        } else {
          await ref.read(addEmergencyContactUseCaseProvider)(draft);
        }
      }
      final updatedContacts =
          await ref.read(loadEmergencyContactUseCaseProvider)();
      state = AsyncData(EmergencyContactViewState(contacts: updatedContacts));
      return ContactSaveResult.saved;
    } catch (_) {
      // Kontak lama (jika ada) dipertahankan; kegagalan tidak boleh terlihat
      // seperti sukses hanya karena kontak lama masih tersimpan.
      state = AsyncData(
        current.copyWith(isSubmitting: false, submitError: saveFailureMessage),
      );
      return ContactSaveResult.failed;
    }
  }

  Future<bool> delete(String id) async {
    final current = state.valueOrNull ?? const EmergencyContactViewState();
    state = AsyncData(current.copyWith(isSubmitting: true));

    try {
      await ref.read(deleteEmergencyContactUseCaseProvider)(id);
      final updatedContacts =
          await ref.read(loadEmergencyContactUseCaseProvider)();
      state = AsyncData(EmergencyContactViewState(contacts: updatedContacts));
      return true;
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isSubmitting: false,
          submitError: 'Gagal menghapus kontak.',
        ),
      );
      return false;
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = state.valueOrNull ?? const EmergencyContactViewState();
    try {
      await ref.read(reorderEmergencyContactsUseCaseProvider)(
          oldIndex, newIndex);
      final updatedContacts =
          await ref.read(loadEmergencyContactUseCaseProvider)();
      state = AsyncData(EmergencyContactViewState(contacts: updatedContacts));
    } catch (_) {
      state = AsyncData(current);
    }
  }
}

final emergencyContactNotifierProvider =
    AsyncNotifierProvider<EmergencyContactNotifier, EmergencyContactViewState>(
  EmergencyContactNotifier.new,
);
