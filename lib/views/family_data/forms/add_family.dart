import 'dart:io';
import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
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
  final _nikController = TextEditingController();
  final _locationController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _descriptionController = TextEditingController();
  XFile? _spousePhoto;

  String _gender = 'Perempuan';
  String _relationshipRole = 'Pasangan';

  @override
  void dispose() {
    _spouseNameController.dispose();
    _nikController.dispose();
    _locationController.dispose();
    _birthYearController.dispose();
    _descriptionController.dispose();
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

      if (currentUser.userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: ID anggota login tidak ditemukan"),
          ),
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
        currentUserId: currentUser.userId!,
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
          "Buat Keluarga",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Config.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Config.primary,
        elevation: 0,
        leading: CustomBackButton(
          color: Config.white,
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              if (currentUser != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Config.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Config.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_border, color: Config.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Menambahkan pasangan untuk:",
                              style: TextStyle(
                                color: Config.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              currentUser.fullName ?? "Anda",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Config.textHead,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Top Avatar & Basic Info Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatarPicker(
                    imageFile: _spousePhoto,
                    onImageSelected: (file) {
                      setState(() => _spousePhoto = file);
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildStyledCardInput(
                          controller: _spouseNameController,
                          hintText: 'Nama Lengkap',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nama wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _buildStyledCardInput(
                          controller: _nikController,
                          hintText: 'Masukan NIT',
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Jenis Kelamin Row
              Row(
                children: [
                  const Text(
                    'Jenis Kelamin',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Config.textHead,
                    ),
                  ),
                  const Spacer(),
                  _buildRadioOption('Laki – Laki'),
                  const SizedBox(width: 12),
                  _buildRadioOption('Perempuan'),
                ],
              ),

              const SizedBox(height: 20),

              // Hubungan Keluarga Dropdown
              _buildLabel('Hubungan Keluarga'),
              _buildStyledDropdownCard(
                value: _relationshipRole,
                items: const ['Pasangan', 'Kepala Keluarga', 'Anak'],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _relationshipRole = val);
                  }
                },
              ),

              const SizedBox(height: 24),

              // Informasi Lanjutan Section Header
              const Text(
                'Informasi Lanjutan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Config.textHead,
                ),
              ),
              const SizedBox(height: 14),

              // Tanggal Lahir
              _buildLabel('Tanggal Lahir'),
              _buildStyledCardInput(
                controller: _birthYearController,
                hintText: 'Tempat, Tanggal Lahir (cth: 1995)',
                readOnly: true,
                onTap: () => _selectYear(context),
              ),

              const SizedBox(height: 16),

              // Alamat tempat tinggal
              _buildLabel('Alamat tempat tinggal'),
              _buildStyledCardInput(
                controller: _locationController,
                hintText: 'masukan alamat',
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Deskripsi Pribadi
              _buildLabel('Deskripsi Pribadi'),
              _buildStyledCardInput(
                controller: _descriptionController,
                hintText: 'Tambahkan Deskripsi',
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Submit Button
              Center(
                child: SizedBox(
                  width: 180,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _saveFamily,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Config.primary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
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
                            "Tambah",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker({
    required XFile? imageFile,
    required Function(XFile?) onImageSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          onImageSelected(picked);
        }
      },
      child: Stack(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade300,
              image: imageFile != null
                  ? DecorationImage(
                      image: FileImage(File(imageFile.path)),
                      fit: BoxFit.cover,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: imageFile == null
                ? Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey.shade500,
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Config.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String value) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Config.primary : Colors.transparent,
              border: Border.all(
                color: isSelected ? Config.primary : Colors.grey.shade400,
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Config.textHead,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Config.textHead,
        ),
      ),
    );
  }

  Widget _buildStyledCardInput({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        style: const TextStyle(fontSize: 14, color: Config.textHead),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStyledDropdownCard({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
          isExpanded: true,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
