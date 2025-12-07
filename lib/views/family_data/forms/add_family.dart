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
  final _birthYearController = TextEditingController();

  File? familyPhoto;

  @override
  void dispose() {
    _headNameController.dispose();
    _locationController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  Future<void> _selectYear(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Pilih Tahun Lahir"),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              initialDate: DateTime.now(),
              selectedDate: DateTime.now(),
              onChanged: (DateTime dateTime) {
                _birthYearController.text = dateTime.year.toString();
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  void _saveFamily() async {
    if (_formKey.currentState!.validate()) {
      final newFamilyHead = UserData(
        fullName: _headNameController.text,
        address: _locationController.text,
        birthYear: _birthYearController.text,
        parentId: null,
      );

      final provider = context.read<UserProvider>();
      final success = await provider.addUser(newFamilyHead);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Keluarga baru berhasil dibuat!'),
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
        elevation: 0,
        leading: CustomBackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ImagePickerField(
                  label: 'Foto Kepala Keluarga',
                  onImageSelected: (file) => setState(() => familyPhoto = file),
                ),
              ),
              const SizedBox(height: 24),

              _buildLabel("Nama Kepala Keluarga"),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _headNameController,
                hint: 'Contoh: Budi Santoso',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              _buildLabel("Tahun Lahir"),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _birthYearController,
                hint: 'Pilih Tahun',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () => _selectYear(context),
              ),
              const SizedBox(height: 16),

              _buildLabel("Alamat"),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _locationController,
                hint: 'Alamat tempat tinggal',
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Ini akan membuat Root (Akar) baru. Gunakan fitur ini hanya jika Anda ingin membuat pohon silsilah yang benar-benar baru.",
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
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(color: Config.textHead, fontWeight: Config.semiBold),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String hint = '',
    IconData? icon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: Config.textSecondary)
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
