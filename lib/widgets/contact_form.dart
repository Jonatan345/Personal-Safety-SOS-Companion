import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../validation/contact_validation.dart';
import 'app_card.dart';
import 'app_input_field.dart';
import 'primary_button.dart';

/// Form kontak darurat: hanya input dan status UI. Aturan input ada di
/// `validation/contact_validation.dart`; penyimpanan dilakukan oleh pemanggil
/// lewat [onSubmit].
class ContactForm extends StatelessWidget {
  const ContactForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.nameFocusNode,
    required this.phoneFocusNode,
    required this.isSubmitting,
    required this.submitError,
    required this.onSubmit,
    required this.onCancel,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final FocusNode nameFocusNode;
  final FocusNode phoneFocusNode;
  final bool isSubmitting;
  final String? submitError;
  final Future<void> Function() onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: AppCard(
        key: const Key('contact-form'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Atur Kontak Darurat',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            AppInputField(
              label: 'Nama Kontak',
              hint: 'Contoh: Ibu Sari',
              controller: nameController,
              focusNode: nameFocusNode,
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => phoneFocusNode.requestFocus(),
              validator: (value) => validateContactName(value ?? ''),
            ),
            const SizedBox(height: 16),
            AppInputField(
              label: 'Nomor Telepon',
              hint: 'Contoh: 911, 112, atau +1 555 123 4567',
              controller: phoneController,
              focusNode: phoneFocusNode,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              helperText: 'Nomor ini digunakan untuk alert darurat.',
              prefixIcon: Icons.phone_outlined,
              validator: (value) => validateContactPhone(value ?? ''),
            ),
            if (submitError != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  submitError!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Simpan Kontak',
              loading: isSubmitting,
              loadingLabel: 'Menyimpan kontak...',
              onPressed: onSubmit,
            ),
            TextButton(
              onPressed: isSubmitting ? null : onCancel,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}
