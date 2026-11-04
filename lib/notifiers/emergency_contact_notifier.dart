import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_contact.dart';
import '../use_cases/emergency_contact_use_cases.dart';

class EmergencyContactViewState {
  const EmergencyContactViewState({
    this.contact,
    this.isSubmitting = false,
    this.submitError,
  });

  final EmergencyContact? contact;
  final bool isSubmitting;
  final String? submitError;

  bool get hasContact => contact != null;

  EmergencyContactViewState copyWith({
    EmergencyContact? contact,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return EmergencyContactViewState(
      contact: contact ?? this.contact,
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

  @override
  Future<EmergencyContactViewState> build() => _loadContact();

  Future<EmergencyContactViewState> _loadContact() async {
    final contact = await ref.read(loadEmergencyContactUseCaseProvider)();
    return EmergencyContactViewState(contact: contact);
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadContact);
  }

  Future<ContactSaveResult> save(EmergencyContactDraft draft) async {
    final current = state.valueOrNull ?? const EmergencyContactViewState();
    if (current.isSubmitting) return ContactSaveResult.alreadySaving;

    state =
        AsyncData(current.copyWith(isSubmitting: true, clearSubmitError: true));

    try {
      final contact =
          await ref.read(saveEmergencyContactUseCaseProvider)(draft);
      state = AsyncData(EmergencyContactViewState(contact: contact));
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
}

final emergencyContactNotifierProvider =
    AsyncNotifierProvider<EmergencyContactNotifier, EmergencyContactViewState>(
  EmergencyContactNotifier.new,
);
