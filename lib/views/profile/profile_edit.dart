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

  XFile? _newProfilePhoto;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;

    _namaController = TextEditingController(text: user?.fullName ?? "");
    _tahunLahirController = TextEditingController(text: user?.birthYear?.toString() ?? "");
    _alamatController = TextEditingController(text: user?.address ?? "");

    if (user?.avatar != null && user!.avatar is String) {
      _currentPhotoUrl = Config.getFullImageUrl(user.avatar as String);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _tahunLahirController.dispose();
    _alamatController.dispose();
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
        leading: CustomBackButton(color: Config.white, onPressed: () => context.pop()),
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

              // Tahun Lahir
              _buildLabel("Tahun Lahir"),
              _buildStyledCardInput(
                controller: _tahunLahirController,
                hintText: "Contoh: 1990",
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
              ),

              const SizedBox(height: 16),

              // Alamat Tempat Tinggal
              _buildLabel("Alamat Tempat Tinggal"),
              _buildStyledCardInput(
                controller: _alamatController,
                hintText: "Masukkan alamat",
                maxLines: 2,
                validator: (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
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
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade300,
            image: _newProfilePhoto != null
                ? DecorationImage(image: FileImage(File(_newProfilePhoto!.path)), fit: BoxFit.cover)
                : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty)
                ? DecorationImage(image: NetworkImage(_currentPhotoUrl!), fit: BoxFit.cover)
                : null,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: _newProfilePhoto == null && (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty)
              ? Icon(Icons.person, size: 50, color: Colors.grey.shade500)
              : null,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _pickProfilePhoto(ImageSource.gallery),
                style: _photoButtonStyle(Config.primary),
                child: const Text('Galeri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              ElevatedButton(
                onPressed: () => _pickProfilePhoto(ImageSource.camera),
                style: _photoButtonStyle(Config.primary.withValues(alpha: 0.65)),
                child: const Text('Kamera', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (!mounted || picked == null) return;
    setState(() => _newProfilePhoto = picked);
  }

  ButtonStyle _photoButtonStyle(Color backgroundColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Config.textHead),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
