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
  final int? parentId; // Terima Parent ID
  const AddFamilyMemberPage({super.key, this.parentId});

  @override
  State<AddFamilyMemberPage> createState() => _AddFamilyMemberPageState();
}

class _AddFamilyMemberPageState extends State<AddFamilyMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthYearController = TextEditingController();

  String _relationType = 'Anak'; // Default: Tambah Anak
  File? memberPhoto;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      if (widget.parentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: ID Keluarga tidak ditemukan")),
        );
        return;
      }

      final newUser = UserData(
        fullName: _nameController.text,
        address: _addressController.text,
        birthYear: _birthYearController.text,
        // Jika Anak -> parentId diisi. Jika Pasangan -> parentId null (karena setara)
        parentId: _relationType == 'Anak' ? widget.parentId : null, 
      );

      final provider = context.read<UserProvider>();
      bool success = false;

      if (_relationType == 'Pasangan') {
        // LOGIC TAMBAH PASANGAN
        success = await provider.addSpouse(
          spouseData: newUser,
          currentUserId: widget.parentId!,
        );
      } else {
        // LOGIC TAMBAH ANAK
        success = await provider.addUser(newUser);
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil menambahkan $_relationType!'),
            backgroundColor: Colors.green,
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
      appBar: AppBar(
        title: const Text(
          "Tambah Anggota",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        leading: CustomBackButton(onPressed: () => context.pop()),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DROPDOWN PILIH STATUS HUBUNGAN
              Text(
                "Status Hubungan",
                style: TextStyle(
                  color: Config.textHead,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _relationType,
                    isExpanded: true,
                    items: ['Anak', 'Pasangan'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _relationType = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: ImagePickerField(
                  label: 'Foto Profil',
                  onImageSelected: (f) => memberPhoto = f,
                ),
              ),
              const SizedBox(height: 24),

              _buildTextField(
                label: 'Nama Lengkap',
                controller: _nameController,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Tahun Lahir',
                controller: _birthYearController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Alamat',
                controller: _addressController,
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
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        )
      ],
    );
  }
}
