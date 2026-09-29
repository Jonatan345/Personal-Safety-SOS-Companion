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

class EmergencyContactNotifier
    extends AsyncNotifier<EmergencyContactViewState> {
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

  Future<void> save(EmergencyContactDraft draft) async {
    final current = state.valueOrNull ?? const EmergencyContactViewState();
    if (current.isSubmitting) return;

    state =
        AsyncData(current.copyWith(isSubmitting: true, clearSubmitError: true));

    try {
      final contact =
          await ref.read(saveEmergencyContactUseCaseProvider)(draft);
      state = AsyncData(EmergencyContactViewState(contact: contact));
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isSubmitting: false,
          submitError: 'Kontak gagal disimpan. Silakan coba lagi.',
        ),
      );
    }
  }
}

final emergencyContactNotifierProvider =
    AsyncNotifierProvider<EmergencyContactNotifier, EmergencyContactViewState>(
  EmergencyContactNotifier.new,
);
