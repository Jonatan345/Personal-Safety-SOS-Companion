import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_contact.dart';
import '../notifiers/emergency_contact_notifier.dart';
import '../theme/app_theme.dart';
import '../utils/snackbars.dart';
import '../widgets/contact_cards.dart';
import '../widgets/contact_form.dart';
import '../widgets/responsive_body.dart';
import '../widgets/state_views.dart';

/// Layar kontak darurat: menghubungkan state (notifier) dengan widget. Input
/// ada di [ContactForm], aturan input di `validation/`, penyimpanan di
/// repository.
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

    final result =
        await ref.read(emergencyContactNotifierProvider.notifier).save(
              EmergencyContactDraft(
                name: _nameController.text.trim(),
                phoneNumber: _phoneController.text.trim(),
              ),
            );
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case ContactSaveResult.saved:
        setState(() => _showForm = false);
        showMessage(messenger, 'Kontak darurat berhasil disimpan',
            replace: true);
      case ContactSaveResult.failed:
        final error =
            ref.read(emergencyContactNotifierProvider).valueOrNull?.submitError;
        showMessage(
          messenger,
          error ?? EmergencyContactNotifier.saveFailureMessage,
          replace: true,
        );
      case ContactSaveResult.alreadySaving:
        break;
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
          loading: () => const LoadingView(
            key: Key('contact-initial-loading'),
            label: 'Memuat kontak darurat…',
          ),
          error: (_, __) => StateMessageView(
            key: const Key('contact-load-error'),
            icon: Icons.error_outline,
            iconColor: AppColors.danger,
            title: 'Kontak darurat tidak dapat dimuat',
            announce: true,
            action: OutlinedButton.icon(
              key: const Key('contact-retry-button'),
              onPressed: () =>
                  ref.read(emergencyContactNotifierProvider.notifier).retry(),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ),
          data: (viewState) => _buildContent(viewState),
        ),
      ),
    );
  }

  Widget _buildContent(EmergencyContactViewState viewState) {
    final contact = viewState.contact;
    return ListView(
      padding: const EdgeInsets.all(20),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        ContentWidth(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (!_showForm) {
                return contact == null
                    ? EmptyContactCard(onAddContact: _openForm)
                    : LoadedContactCard(
                        contact: contact,
                        onEdit: () => _openForm(contact),
                      );
              }
              return _buildFormLayout(
                viewState,
                wide: Breakpoints.isWide(constraints.maxWidth),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFormLayout(EmergencyContactViewState viewState,
      {required bool wide}) {
    final form = ContactForm(
      formKey: _formKey,
      nameController: _nameController,
      phoneController: _phoneController,
      nameFocusNode: _nameFocusNode,
      phoneFocusNode: _phoneFocusNode,
      isSubmitting: viewState.isSubmitting,
      submitError: viewState.submitError,
      onSubmit: () => _submit(viewState),
      onCancel: () => setState(() => _showForm = false),
    );
    final summary = AnimatedBuilder(
      animation: Listenable.merge([_nameController, _phoneController]),
      builder: (context, _) => ContactSummaryCard(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
      ),
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [form, const SizedBox(height: 20), summary],
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
  }
}
