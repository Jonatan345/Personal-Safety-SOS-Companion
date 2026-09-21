import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../widgets/app_input_field.dart';
import '../widgets/app_card.dart';

class ContactSetupScreen extends StatefulWidget {
  const ContactSetupScreen({super.key});

  @override
  State<ContactSetupScreen> createState() => _ContactSetupScreenState();
}

class _ContactSetupScreenState extends State<ContactSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool loading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulasi: kontak darurat berhasil disimpan')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kontak Darurat')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Column(
                    children: [
                      AppInputField(
                        label: 'Nama Kontak',
                        hint: 'Contoh: Ibu Sari',
                        controller: nameController,
                        prefixIcon: Icons.person_outline,
                        validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      AppInputField(
                        label: 'Nomor Telepon',
                        hint: 'Contoh: 911, 112, atau +1 555 123 4567',
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        validator: (v) {
                          final phoneNumber = v?.trim() ?? '';
                          final digitCount = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '').length;

                          if (digitCount < 3) {
                            return 'Masukkan minimal 3 digit';
                          }

                          if (!RegExp(r'^[0-9+()\-\s.]+$').hasMatch(phoneNumber)) {
                            return 'Gunakan angka dan simbol nomor telepon yang valid';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(label: 'Simpan Kontak', loading: loading, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
