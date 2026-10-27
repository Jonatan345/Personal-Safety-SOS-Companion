import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_contact.dart';
import '../notifiers/emergency_contact_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_input_field.dart';
import '../widgets/primary_button.dart';

class ContactSetupScreen extends ConsumerStatefulWidget {
  const ContactSetupScreen({super.key});

  @override
  ConsumerState<ContactSetupScreen> createState() => _ContactSetupScreenState();
}

class _ContactSetupScreenState extends ConsumerState<ContactSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  bool _showForm = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _openForm([EmergencyContact? contact]) {
    _nameController.text = contact?.name ?? '';
    _phoneController.text = contact?.phoneNumber ?? '';
    setState(() => _showForm = true);
  }

  Future<void> _submit(EmergencyContactViewState viewState) async {
    if (viewState.isSubmitting || !_formKey.currentState!.validate()) return;

    await ref.read(emergencyContactNotifierProvider.notifier).save(
          EmergencyContactDraft(
            name: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
          ),
        );

    if (!mounted) return;
    final savedState = ref.read(emergencyContactNotifierProvider).valueOrNull;
    if (savedState?.hasContact ?? false) {
      setState(() => _showForm = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kontak darurat berhasil disimpan')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedState?.submitError ?? 'Kontak gagal disimpan. Coba lagi.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emergencyContactNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kontak Darurat')),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: state.when(
          loading: () => const _InitialLoadingState(),
          error: (_, __) => _LoadErrorState(
            onRetry: () =>
                ref.read(emergencyContactNotifierProvider.notifier).retry(),
          ),
          data: (viewState) => _ContactContent(
            viewState: viewState,
            showForm: _showForm,
            formKey: _formKey,
            nameController: _nameController,
            phoneController: _phoneController,
            nameFocusNode: _nameFocusNode,
            phoneFocusNode: _phoneFocusNode,
            onAddOrEdit: () => _openForm(viewState.contact),
            onCancel: () => setState(() => _showForm = false),
            onSubmit: () => _submit(viewState),
          ),
        ),
      ),
    );
  }
}

class _InitialLoadingState extends StatelessWidget {
  const _InitialLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('contact-initial-loading'),
      child: CircularProgressIndicator(),
    );
  }
}

class _LoadErrorState extends StatelessWidget {
  const _LoadErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('contact-load-error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 52),
            const SizedBox(height: 12),
            const Text('Kontak darurat tidak dapat dimuat'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('contact-retry-button'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactContent extends StatelessWidget {
  const _ContactContent({
    required this.viewState,
    required this.showForm,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.nameFocusNode,
    required this.phoneFocusNode,
    required this.onAddOrEdit,
    required this.onCancel,
    required this.onSubmit,
  });

  final EmergencyContactViewState viewState;
  final bool showForm;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final FocusNode nameFocusNode;
  final FocusNode phoneFocusNode;
  final VoidCallback onAddOrEdit;
  final VoidCallback onCancel;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final contact = viewState.contact;
    return ListView(
      padding: const EdgeInsets.all(20),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        SizedBox(
          width: double.infinity,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 700;
                  if (contact == null && !showForm) {
                    return _EmptyContactState(onAddContact: onAddOrEdit);
                  }
                  if (!showForm) {
                    return _LoadedContactState(
                      contact: contact!,
                      onEdit: onAddOrEdit,
                    );
                  }

                  final form = _ContactForm(
                    formKey: formKey,
                    nameController: nameController,
                    phoneController: phoneController,
                    nameFocusNode: nameFocusNode,
                    phoneFocusNode: phoneFocusNode,
                    isSubmitting: viewState.isSubmitting,
                    submitError: viewState.submitError,
                    onSubmit: onSubmit,
                    onCancel: onCancel,
                  );
                  final summary = AnimatedBuilder(
                    animation: Listenable.merge([
                      nameController,
                      phoneController,
                    ]),
                    builder: (context, _) => _ContactSummary(
                      name: nameController.text,
                      phoneNumber: phoneController.text,
                    ),
                  );
                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        form,
                        const SizedBox(height: 20),
                        summary,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: form),
                      const SizedBox(width: 24),
                      Expanded(child: summary),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactSummary extends StatelessWidget {
  const _ContactSummary({required this.name, required this.phoneNumber});

  final String name;
  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const Key('contact-summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.primary, size: 32),
          const SizedBox(height: 12),
          Text(
            name.trim().isEmpty ? 'Kontak darurat' : name.trim(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            phoneNumber.trim().isEmpty
                ? 'Nomor telepon akan tampil di sini'
                : phoneNumber.trim(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kontak ini akan menerima pemberitahuan saat SOS dikirim.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Pastikan nama dan nomor telepon sudah benar sebelum menyimpan.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EmptyContactState extends StatelessWidget {
  const _EmptyContactState({required this.onAddContact});

  final VoidCallback onAddContact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const Key('contact-empty-state'),
      child: Column(
        children: [
          const Icon(Icons.contact_phone_outlined,
              color: AppColors.textSecondary, size: 48),
          const SizedBox(height: 12),
          const Text('Belum ada kontak darurat',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'Tambahkan satu kontak yang akan menerima alert darurat Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Tambah Kontak Darurat',
            icon: Icons.add,
            onPressed: onAddContact,
          ),
        ],
      ),
    );
  }
}

class _LoadedContactState extends StatelessWidget {
  const _LoadedContactState({required this.contact, required this.onEdit});

  final EmergencyContact contact;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const Key('contact-data-state'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kontak darurat aktif',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(contact.name)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(contact.phoneNumber)),
            ],
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Ubah Kontak'),
          ),
        ],
      ),
    );
  }
}

class _ContactForm extends StatelessWidget {
  const _ContactForm({
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
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Nama wajib diisi'
                  : null,
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
              validator: _validatePhoneNumber,
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

  String? _validatePhoneNumber(String? value) {
    final phoneNumber = value?.trim() ?? '';
    final digitCount = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '').length;

    if (digitCount < 3) return 'Masukkan minimal 3 digit';
    if (!RegExp(r'^[0-9+()\-\s.]+$').hasMatch(phoneNumber)) {
      return 'Gunakan angka dan simbol nomor telepon yang valid';
    }
    return null;
  }
}
