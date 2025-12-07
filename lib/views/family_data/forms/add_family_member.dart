import 'dart:io';
import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/components/image_picker_field.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AddFamilyMemberPage extends StatefulWidget {
  final int? parentId;
  final String? parentName; // Tambahan untuk UI

  const AddFamilyMemberPage({super.key, this.parentId, this.parentName});

  @override
  State<AddFamilyMemberPage> createState() => _AddFamilyMemberPageState();
}

class _AddFamilyMemberPageState extends State<AddFamilyMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthYearController = TextEditingController();

  String _relationType = 'Anak'; 
  File? memberPhoto;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
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

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      if (widget.parentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: ID Parent tidak ditemukan")),
        );
        return;
      }

      final newUser = UserData(
        fullName: _nameController.text,
        address: _addressController.text,
        birthYear: _birthYearController.text,
        parentId: _relationType == 'Anak' ? widget.parentId : null,
      );

      final provider = context.read<UserProvider>();
      bool success = false;

      if (_relationType == 'Pasangan') {
        success = await provider.addSpouse(
          spouseData: newUser,
          currentUserId: widget.parentId!,
        );
      } else {
        success = await provider.addUser(newUser);
      }
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil menambahkan $_relationType!'),
            backgroundColor: Config.primary,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Gagal menyimpan'),
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
          "Tambah Anggota",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        leading: CustomBackButton(onPressed: () => context.pop()),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.parentName != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Config.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Config.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add_alt_1,
                        color: Config.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Menambahkan hubungan ke:",
                              style: TextStyle(
                                fontSize: 12,
                                color: Config.textSecondary,
                              ),
                            ),
                            Text(
                              widget.parentName!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Config.textHead,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Center(
                child: ImagePickerField(
                  label: 'Foto Profil',
                  onImageSelected: (f) => memberPhoto = f,
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel("Status Hubungan"),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Anak'),
                      value: 'Anak',
                      groupValue: _relationType,
                      activeColor: Config.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) =>
                          setState(() => _relationType = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Pasangan'),
                      value: 'Pasangan',
                      groupValue: _relationType,
                      activeColor: Config.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) =>
                          setState(() => _relationType = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Nama Lengkap',
                controller: _nameController,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Tahun Lahir',
                controller: _birthYearController,
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () => _selectYear(context),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Alamat',
                controller: _addressController,
                icon: Icons.location_on_outlined,
                maxLines: 2,
                isRequired: false,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _saveData,
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
                      : Text(
                          "Simpan $_relationType",
                          style: const TextStyle(
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
    required String label,
    required TextEditingController controller,
    IconData? icon,
    int maxLines = 1,
    bool isRequired = true,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          validator: isRequired
              ? (v) => v == null || v.isEmpty ? '$label wajib diisi' : null
              : null,
          decoration: InputDecoration(
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
        ),
      ],
    );
  }
}
