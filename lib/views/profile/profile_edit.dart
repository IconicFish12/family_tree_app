import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/auth_provider.dart';
import 'package:family_tree_app/data/provider/family_edit_form_provider.dart';
import 'package:family_tree_app/data/provider/image_picker_provider.dart';
import 'package:family_tree_app/data/provider/tree_provider.dart';
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
  late final FamilyEditFormProvider _profileFormProvider;
  late final ImagePickerProvider _imagePickerProvider;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    final currentPhotoUrl = Config.getAvatarUrl(
      avatar: user?.avatar,
      avatarUrl: user?.avatarUrl,
    );

    _profileFormProvider = FamilyEditFormProvider(
      initialName: user?.fullName ?? '',
      initialGender: user?.gender,
      initialAddress: user?.address,
      initialBirthYear: user?.birthYear,
    );
    _imagePickerProvider = ImagePickerProvider(
      initialImagePath: currentPhotoUrl,
      isNetworkImage: currentPhotoUrl != null,
    );
  }

  @override
  void dispose() {
    _profileFormProvider.dispose();
    _imagePickerProvider.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!(_profileFormProvider.formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      _showError('Data pengguna tidak tersedia. Silakan muat ulang.');
      return;
    }

    final result = await userProvider.updateProfile(
      data: UserData(
        fullName: _profileFormProvider.nameController.text.trim(),
        gender: currentUser.gender ?? _profileFormProvider.gender,
        address: _emptyToNull(_profileFormProvider.addressController.text),
        birthYear: _emptyToNull(_profileFormProvider.birthYearController.text),
        avatar: _imagePickerProvider.pickedFile,
      ),
    );

    if (!mounted) return;
    if (result == null) {
      _showError(userProvider.errorMessage ?? 'Gagal memperbarui profil.');
      return;
    }

    authProvider.updateUser(result);
    await context.read<TreeProvider>().refreshCurrentTree();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil berhasil diperbarui.'),
        backgroundColor: Config.primary,
      ),
    );
    context.pop(true);
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<UserProvider, bool>(
      (provider) => provider.isSubmitting,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ImagePickerProvider>.value(
          value: _imagePickerProvider,
        ),
        ChangeNotifierProvider<FamilyEditFormProvider>.value(
          value: _profileFormProvider,
        ),
      ],
      child: Scaffold(
        backgroundColor: Config.background,
        appBar: AppBar(
          backgroundColor: const Color(0xFF559260),
          elevation: 0,
          leading: CustomBackButton(
            color: Config.white,
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Edit Profil',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _profileFormProvider.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhotoPickerRow(),
                const SizedBox(height: 24),
                _buildLabel('Nama Lengkap'),
                _buildStyledCardInput(
                  controller: _profileFormProvider.nameController,
                  hintText: 'Nama Lengkap',
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama lengkap wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildLabel('Gender (opsional)'),
                _buildGenderDropdown(),
                const SizedBox(height: 16),
                _buildLabel('Tahun Lahir (opsional)'),
                _buildStyledCardInput(
                  controller: _profileFormProvider.birthYearController,
                  hintText: 'Contoh: 1990',
                  keyboardType: TextInputType.number,
                  validator: _validateOptionalYear,
                ),
                const SizedBox(height: 16),
                _buildLabel('Alamat Tempat Tinggal (opsional)'),
                _buildStyledCardInput(
                  controller: _profileFormProvider.addressController,
                  hintText: 'Masukkan alamat',
                  maxLines: 2,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                            'Simpan Perubahan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPickerRow() {
    return Consumer<ImagePickerProvider>(
      builder: (context, imageProvider, child) {
        final bytes = imageProvider.pickedBytes;
        final networkUrl = imageProvider.networkImageUrl;
        final ImageProvider<Object>? avatarImage = bytes != null
            ? MemoryImage(bytes)
            : networkUrl != null && networkUrl.isNotEmpty
            ? NetworkImage(networkUrl)
            : null;

        return Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
                image: avatarImage == null
                    ? null
                    : DecorationImage(image: avatarImage, fit: BoxFit.cover),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: avatarImage == null
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
                    child: const Text(
                      'Galeri',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickProfilePhoto(ImageSource.camera),
                    style: _photoButtonStyle(
                      Config.primary.withValues(alpha: 0.65),
                    ),
                    child: const Text(
                      'Kamera',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGenderDropdown() {
    return Consumer<FamilyEditFormProvider>(
      builder: (context, formProvider, child) {
        final gender = formProvider.gender;
        final isGenderLocked = gender != null;
        final genderOptions = isGenderLocked
            ? <PersonGender>[gender]
            : PersonGender.values;
        return Container(
          decoration: _cardDecoration(),
          child: DropdownButtonFormField<String>(
            key: ValueKey('profile-gender-${gender?.apiValue ?? 'empty'}'),
            initialValue: gender?.apiValue ?? '',
            isExpanded: true,
            decoration:
                const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ).copyWith(
                  helperText: isGenderLocked
                      ? 'Gender sudah dipilih dan tidak dapat diubah.'
                      : null,
                ),
            items: [
              if (!isGenderLocked)
                const DropdownMenuItem(value: '', child: Text('Tidak diisi')),
              ...genderOptions.map(
                (option) => DropdownMenuItem(
                  value: option.apiValue,
                  child: Text(option.label),
                ),
              ),
            ],
            onChanged: isGenderLocked
                ? null
                : (value) =>
                      formProvider.selectGender(_genderFromApiValue(value)),
          ),
        );
      },
    );
  }

  PersonGender? _genderFromApiValue(String? value) {
    for (final gender in PersonGender.values) {
      if (gender.apiValue == value) return gender;
    }
    return null;
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    try {
      await _imagePickerProvider.pickImage(source);
    } catch (_) {
      if (mounted) _showError('Foto profil gagal dipilih. Silakan coba lagi.');
    }
  }

  String? _validateOptionalYear(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final year = int.tryParse(text);
    if (year == null || year < 1900 || year > DateTime.now().year) {
      return 'Masukkan tahun yang benar.';
    }
    return null;
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
      padding: const EdgeInsets.only(bottom: 8, top: 4),
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
      decoration: _cardDecoration(),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Config.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
