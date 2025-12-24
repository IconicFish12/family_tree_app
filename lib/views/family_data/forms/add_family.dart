import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/components/image_picker_field.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/auth_provider.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AddFamilyPage extends StatefulWidget {
  const AddFamilyPage({super.key});

  @override
  State<AddFamilyPage> createState() => _AddFamilyPageState();
}

class _AddFamilyPageState extends State<AddFamilyPage> {
  final _formKey = GlobalKey<FormState>();
  final _spouseNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _birthYearController = TextEditingController();
  XFile? _spousePhoto;

  @override
  void dispose() {
    _spouseNameController.dispose();
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
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Sesi login tidak valid")),
        );
        return;
      }

      final spouseData = UserData(
        fullName: _spouseNameController.text,
        address: _locationController.text,
        birthYear: _birthYearController.text,
        parentId: null,
        avatar: _spousePhoto,
      );

      final userProvider = context.read<UserProvider>();

      final success = await userProvider.addSpouse(
        spouseData: spouseData,
        currentUserId: currentUser.userId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pasangan berhasil ditambahkan! Keluarga terbentuk.'),
            backgroundColor: Config.primary,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProvider.errorMessage ?? 'Gagal menyimpan data'),
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
    final currentUser = context.select<AuthProvider, dynamic>(
      (p) => p.currentUser,
    );

    return Scaffold(
      backgroundColor: Config.background,
      appBar: AppBar(
        title: const Text(
          "Buat Keluarga (Pasangan)",
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
              // Info Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                          children: [
                            const TextSpan(
                              text: "Menambahkan pasangan untuk: \n",
                            ),
                            TextSpan(
                              text: currentUser?.fullName ?? "Anda",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Center(
                child: ImagePickerField(
                  label: 'Foto Pasangan',
                  onImageSelected: (file) =>
                      setState(() => _spousePhoto = file),
                ),
              ),
              const SizedBox(height: 24),

              _buildLabel("Nama Pasangan"),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _spouseNameController,
                hint: 'Nama Suami / Istri',
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
                          "Simpan Pasangan",
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
