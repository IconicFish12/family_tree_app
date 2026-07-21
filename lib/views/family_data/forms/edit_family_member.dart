import 'dart:io';
import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/auth_provider.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditFamilyMemberPage extends StatefulWidget {
  final ChildMember member;

  const EditFamilyMemberPage({super.key, required this.member});

  @override
  State<EditFamilyMemberPage> createState() => _EditFamilyMemberPageState();
}

class _EditFamilyMemberPageState extends State<EditFamilyMemberPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _nitController;
  late TextEditingController _tahunLahirController;
  late TextEditingController _alamatController;
  late TextEditingController _deskripsiController;

  XFile? _newPhoto;
  String? _currentPhotoUrl;
  String _gender = 'Laki – Laki';
  late String _relationshipRole;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.member.name);
    _nitController = TextEditingController(text: widget.member.nit);
    _tahunLahirController =
        TextEditingController(text: widget.member.birthYear ?? "");
    _alamatController =
        TextEditingController(text: widget.member.location ?? "");
    _deskripsiController = TextEditingController();

    final initialRole = widget.member.role;
    if (initialRole != null && initialRole.startsWith('Anak')) {
      _relationshipRole = 'Anak';
    } else if (initialRole == 'Kepala Keluarga' || initialRole == 'Pasangan') {
      _relationshipRole = initialRole!;
    } else {
      _relationshipRole = 'Anak';
    }

    if (widget.member.gender != null && widget.member.gender!.isNotEmpty) {
      final g = widget.member.gender!.toLowerCase();
      if (g == 'p' || g.startsWith('perempuan') || g == 'female') {
        _gender = 'Perempuan';
      } else {
        _gender = 'Laki – Laki';
      }
    }

    if (widget.member.photoUrl != null && widget.member.photoUrl!.isNotEmpty) {
      _currentPhotoUrl = Config.getFullImageUrl(widget.member.photoUrl!);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nitController.dispose();
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

    final bool isCurrentUser =
        (currentUser != null && widget.member.id == currentUser.userId);

    if (isCurrentUser) {
      final updatedData = UserData(
        fullName: _namaController.text,
        address: _alamatController.text,
        birthYear: _tahunLahirController.text,
        avatar: _newPhoto,
      );

      final result = await userProvider.updateProfile(data: updatedData);

      if (!mounted) return;

      if (result != null) {
        authProvider.updateUser(result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data profil Anda berhasil diperbarui!"),
            backgroundColor: Config.primary,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(userProvider.errorMessage ?? "Gagal memperbarui profil"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (widget.member.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ID Anggota tidak valid untuk diperbarui."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = await userProvider.updateFamilyMember(
        memberId: widget.member.id!,
        fullName: _namaController.text,
        address: _alamatController.text,
        birthYear: _tahunLahirController.text,
        gender: _gender,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Data ${widget.member.name} berhasil diperbarui!"),
            backgroundColor: Config.primary,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                userProvider.errorMessage ?? "Gagal memperbarui anggota keluarga."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Hapus Anggota Keluarga",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Config.textHead,
          ),
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus ${widget.member.name} dari daftar keluarga? Tindakan ini tidak dapat dibatalkan.",
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Batal",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Hapus",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDelete() async {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final currentUser = authProvider.currentUser;
    final bool isCurrentUser =
        (currentUser != null && widget.member.id == currentUser.userId);

    if (isCurrentUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tidak dapat menghapus akun profil utama."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.member.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ID Anggota tidak valid untuk dihapus."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await userProvider.deleteFamilyMember(widget.member.id!);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Anggota keluarga ${widget.member.name} berhasil dihapus!"),
          backgroundColor: Config.primary,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              userProvider.errorMessage ?? "Gagal menghapus anggota keluarga."),
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
      backgroundColor: Config.background,
      appBar: AppBar(
        backgroundColor: Config.primary,
        elevation: 0,
        leading: CustomBackButton(
          color: Config.white,
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Edit Anggota Keluarga",
          style: TextStyle(
            color: Config.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Config.white),
            tooltip: 'Hapus Anggota',
            onPressed: _showDeleteConfirmation,
          ),
          const SizedBox(width: 8),
        ],
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

              // NIT
              _buildLabel("NIT"),
              _buildStyledCardInput(
                controller: _nitController,
                hintText: "Nama NIT Anggota",
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

              // Centered Action Buttons Row (Hapus & Update)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: isSubmitting ? null : _showDeleteConfirmation,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        "Hapus",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 150,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _handleUpdate,
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
                              "Update",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
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
            image: _newPhoto != null
                ? DecorationImage(
                    image: FileImage(File(_newPhoto!.path)),
                    fit: BoxFit.cover,
                  )
                : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(_currentPhotoUrl!),
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
          child: (_newPhoto == null &&
                  (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty))
              ? Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.grey.shade500,
                )
              : null,
        ),
        const SizedBox(width: 20),

        Row(
          children: [
            ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                final picked =
                    await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  setState(() => _newPhoto = picked);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Config.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Galeri',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                final picked =
                    await picker.pickImage(source: ImageSource.camera);
                if (picked != null) {
                  setState(() => _newPhoto = picked);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Config.primary.withValues(alpha: 0.65),
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Kamera',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
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
