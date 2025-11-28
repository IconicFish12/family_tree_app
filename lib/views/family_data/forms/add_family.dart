import 'dart:io';
import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/components/image_picker_field.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AddFamilyPage extends StatefulWidget {
  const AddFamilyPage({super.key});

  @override
  State<AddFamilyPage> createState() => _AddFamilyPageState();
}

class _AddFamilyPageState extends State<AddFamilyPage> {
  final _formKey = GlobalKey<FormState>();
  final _headNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _birthYearController = TextEditingController(); // Tambahan

  File? familyPhoto;

  @override
  void dispose() {
    _headNameController.dispose();
    _locationController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  void _saveFamily() async {
    if (_formKey.currentState!.validate()) {
      // 1. Buat Object Kepala Keluarga
      final newFamilyHead = UserData(
        fullName: _headNameController.text,
        address: _locationController.text,
        birthYear: _birthYearController.text,
        parentId: null, // Root Node (Tidak punya bapak di tree ini)
        // avatar: familyPhoto (Logic upload foto skip dlu atau implement terpisah)
      );

      // 2. Panggil Provider
      final provider = context.read<UserProvider>();
      final success = await provider.addUser(newFamilyHead);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Keluarga ${_headNameController.text} berhasil dibuat! Silakan tambah anggota keluarga.',
            ),
            backgroundColor: Config.primary,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Gagal menyimpan data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<UserProvider, bool>(
      (p) => p.isSubmitting,
    );

    return Scaffold(
      backgroundColor: Config.background,
      appBar: AppBar(
        title: const Text(
          "Buat Keluarga Baru",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: CustomBackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ImagePickerField(
                label: 'Foto Kepala Keluarga',
                onImageSelected: (file) => setState(() => familyPhoto = file),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                label: 'Nama Kepala Keluarga', 
                controller: _headNameController,
                hint: 'Contoh: Budi Santoso',
                isRequired: true
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Tahun Lahir',
                controller: _birthYearController,
                hint: 'Contoh: 1980',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Alamat', 
                controller: _locationController,
                hint: 'Alamat tempat tinggal',
                maxLines: 2
              ),
              const SizedBox(height: 32),
              
              // INFO TEXT
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Setelah menyimpan Kepala Keluarga, Anda dapat menambahkan Pasangan dan Anak melalui halaman detail.",
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _saveFamily,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Config.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text(
                          "Simpan Keluarga",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Config.textHead, fontWeight: Config.semiBold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: isRequired
              ? (v) => v == null || v.isEmpty ? '$label wajib diisi' : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        )
      ],
    );
  }
}
