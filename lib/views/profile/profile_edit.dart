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

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _tahunLahirController;
  late TextEditingController _alamatController;
  late TextEditingController _deskripsiController;

  XFile? _newProfilePhoto;
  String? _currentPhotoUrl;
  String _gender = 'Laki – Laki';
  String _relationshipRole = 'Kepala Keluarga';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;

    _namaController = TextEditingController(text: user?.fullName ?? "");
    _tahunLahirController = TextEditingController(text: user?.birthYear?.toString() ?? "");
    _alamatController = TextEditingController(text: user?.address ?? "");
    _deskripsiController = TextEditingController();

    if (user?.avatar != null && user!.avatar is String) {
      _currentPhotoUrl = Config.getFullImageUrl(user.avatar as String);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _tahunLahirController.dispose();
    _alamatController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    final updatedData = UserData(
      fullName: _namaController.text,
      address: _alamatController.text,
      birthYear: _tahunLahirController.text,
      avatar: _newProfilePhoto,
    );

    final result = await userProvider.updateProfile(data: updatedData);

    if (!mounted) return;

    if (result != null) {
      authProvider.updateUser(result);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profil berhasil diperbarui!"), backgroundColor: Config.primary));
      context.pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userProvider.errorMessage ?? "Gagal update profil"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<UserProvider, bool>((p) => p.isSubmitting);

    return Scaffold(
      backgroundColor: Config.background,
      appBar: AppBar(
        backgroundColor: Color(0xFF559260),
        elevation: 0,
        leading: CustomBackButton(
          color: Config.white,
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Picker Row (Avatar + Galeri & Kamera buttons)
              _buildPhotoPickerRow(),

              const SizedBox(height: 24),

              // Nama Lengkap
              _buildLabel("Nama Lengkap"),
              _buildStyledCardInput(
                controller: _namaController,
                hintText: "Nama Lengkap",
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),

              const SizedBox(height: 16),

              // Hubungan Keluarga
              _buildLabel("hubungan Keluarga"),
              _buildStyledDropdownCard(
                value: _relationshipRole,
                items: const ['Kepala Keluarga', 'Pasangan', 'Anak'],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _relationshipRole = val);
                  }
                },
              ),

              const SizedBox(height: 16),

              // Jenis Kelamin Radio
              Row(
                children: [
                  const Text(
                    'Jenis Kelamin',
                    style: TextStyle(
                      fontSize: 13,
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

              const SizedBox(height: 16),

              // Tempat, Tanggal Lahir
              _buildLabel("Tempat, Tanggal Lahir"),
              _buildStyledCardInput(
                controller: _tahunLahirController,
                hintText: "Tempat, Tanggal Lahir",
              ),

              const SizedBox(height: 16),

              // Alamat Tempat Tinggal
              _buildLabel("Alamat Tempat Tinggal"),
              _buildStyledCardInput(
                controller: _alamatController,
                hintText: "masukan alamat",
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Deskripsi Pribadi
              _buildLabel("Deskripsi Pribadi"),
              _buildStyledCardInput(
                controller: _deskripsiController,
                hintText: "Tambahkan Deskripsi",
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    elevation: 2,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Simpan Perubahan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPickerRow() {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          minLines: minLines,
          keyboardType: isMultiline ? TextInputType.multiline : keyboardType,
          textAlignVertical: isMultiline ? TextAlignVertical.top : TextAlignVertical.center,
          validator: (v) => v == null || v.isEmpty ? '$label wajib diisi' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey[600]) : null,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isMultiline ? 16 : 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
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
    final safeValue = items.contains(value) ? value : items.first;
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
          value: safeValue,
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
