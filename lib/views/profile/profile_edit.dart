import 'package:family_tree_app/components/image_picker_field.dart';
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
    _tahunLahirController = TextEditingController(
      text: user?.birthYear?.toString() ?? "",
    );
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

    final result = await userProvider.updateProfile(
      id: currentUser.userId.toString(),
      data: updatedData,
    );

    if (!mounted) return;

    // 3. Handle Hasil
    if (result != null) {
      authProvider.updateUser(result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil berhasil diperbarui!"),
          backgroundColor: Config.primary,
        ),
      );
      context.pop();
    } else {
      // GAGAL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.errorMessage ?? "Gagal update profil"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<UserProvider, bool>(
      (p) => p.isSubmitting,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: CustomBackButton(onPressed: () => context.pop()),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ImagePickerField(
                  label: "Foto Profil",
                  initialImagePath: _currentPhotoUrl,
                  isNetworkImage: true,
                  onImageSelected: (file) {
                    setState(() {
                      _newProfilePhoto = file;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                controller: _namaController,
                label: "Nama Lengkap",
                hint: "Masukan nama lengkap",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _tahunLahirController,
                label: "Tahun Lahir",
                hint: "Contoh: 1990",
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _alamatController,
                label: "Alamat Tempat Tinggal",
                hint: "Masukan alamat lengkap",
                icon: Icons.location_on_outlined,
                minLines: 1,
                maxLines: 6,
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 2,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Simpan Perubahan",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    int minLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isMultiline = maxLines > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          minLines: minLines,
          keyboardType: isMultiline ? TextInputType.multiline : keyboardType,
          textAlignVertical: isMultiline
              ? TextAlignVertical.top
              : TextAlignVertical.center,
          validator: (v) =>
              v == null || v.isEmpty ? '$label wajib diisi' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: icon != null
                ? Icon(icon, color: Colors.grey[600])
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isMultiline ? 16 : 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: Color(0xFF4CAF50),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
