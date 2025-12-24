import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/components/image_picker_field.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AddFamilyMemberPage extends StatefulWidget {
  final int? parentId;
  final String? parentName;

  const AddFamilyMemberPage({super.key, this.parentId, this.parentName});

  @override
  State<AddFamilyMemberPage> createState() => _AddFamilyMemberPageState();
}

class _AddFamilyMemberPageState extends State<AddFamilyMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthYearController = TextEditingController();
  XFile? memberPhoto;

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
          const SnackBar(content: Text("Error: ID Parent tidak ditemukan")),
        );
        return;
      }

      final newChild = UserData(
        fullName: _nameController.text,
        address: _addressController.text,
        birthYear: _birthYearController.text,
        parentId: widget.parentId,
        avatar: memberPhoto,
      );

      final provider = context.read<UserProvider>();

      final success = await provider.addChild(newChild);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil menambahkan Anak!'),
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
          "Tambah Anak",
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Config.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Config.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.child_care, color: Config.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Menambahkan anak untuk:",
                              style: TextStyle(
                                fontSize: 12,
                                color: Config.textSecondary,
                              ),
                            ),
                            Text(
                              widget.parentName!,
                              style: TextStyle(
                                fontWeight: Config.bold,
                                color: Config.textHead,
                                fontSize: 16,
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
                  label: 'Foto Anak',
                  onImageSelected: (f) => memberPhoto = f,
                ),
              ),
              const SizedBox(height: 24),

              _buildTextField(
                label: 'Nama Lengkap',
                controller: _nameController,
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Tahun Lahir',
                controller: _birthYearController,
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Alamat',
                controller: _addressController,
                icon: Icons.location_on,
                maxLines: 1,
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
                      : const Text(
                          "Simpan Anak",
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
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (v) => v == null || v.isEmpty ? '$label wajib diisi' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, color: Config.textSecondary)
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
