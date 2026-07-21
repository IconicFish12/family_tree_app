import 'dart:io';
import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/auth_provider.dart';
import 'package:family_tree_app/data/provider/marriage_form_provider.dart';
import 'package:family_tree_app/data/provider/tree_provider.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AddFamilyPage extends StatefulWidget {
  final int? initialMemberId;

  const AddFamilyPage({super.key, this.initialMemberId});

  @override
  State<AddFamilyPage> createState() => _AddFamilyPageState();
}

class _AddFamilyPageState extends State<AddFamilyPage> {
  final _formKey = GlobalKey<FormState>();
  final _spouseNameController = TextEditingController();
  final _nikController = TextEditingController();
  final _locationController = TextEditingController();
  final _birthYearController = TextEditingController();
  final MarriageFormProvider _formProvider = MarriageFormProvider();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    if (!mounted) return;
    final actor = context.read<AuthProvider>().currentUser;
    if (actor == null) return;
    await _formProvider.initialize(
      userProvider: context.read<UserProvider>(),
      actor: actor,
      initialMemberId: widget.initialMemberId,
    );
  }

  String _gender = 'Perempuan';
  String _relationshipRole = 'Pasangan';

  @override
  void dispose() {
    _spouseNameController.dispose();
    _nikController.dispose();
    _locationController.dispose();
    _birthYearController.dispose();
    _formProvider.dispose();
    super.dispose();
  }

  Future<void> _saveFamily() async {
    if (!_formKey.currentState!.validate()) return;
    final memberId = _formProvider.selectedMemberId;
    if (memberId == null) {
      _showError('Pilih anggota keluarga terlebih dahulu.');
      return;
    }

    final userProvider = context.read<UserProvider>();
    final success = await userProvider.addSpouse(
      memberId: memberId,
      spouseData: UserData(
        fullName: _spouseNameController.text.trim(),
        address: _emptyToNull(_locationController.text),
        birthYear: _emptyToNull(_birthYearController.text),
      ),
    );

    if (!mounted) return;
    if (!success) {
      _showError(userProvider.errorMessage ?? 'Pasangan gagal ditambahkan.');
      return;
    }

    await context.read<TreeProvider>().refreshCurrentTree();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pasangan berhasil ditambahkan.'),
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

    return ChangeNotifierProvider<MarriageFormProvider>.value(
      value: _formProvider,
      child: Consumer<MarriageFormProvider>(
        builder: (context, formProvider, child) {
          return Scaffold(
            backgroundColor: Config.background,
            appBar: AppBar(
              title: const Text(
                'Tambah Pasangan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: CustomBackButton(onPressed: () => context.pop()),
            ),
            body: formProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGuidance(),
                          const SizedBox(height: 20),
                          if (formProvider.errorMessage != null)
                            _buildErrorBox(formProvider.errorMessage!),
                          DropdownButtonFormField<int>(
                            key: ValueKey(formProvider.selectedMemberId),
                            initialValue: formProvider.selectedMemberId,
                            isExpanded: true,
                            decoration: _inputDecoration(
                              label: 'Pasangan akan ditambahkan untuk',
                              icon: Icons.family_restroom,
                            ),
                            items: formProvider.availableMembers
                                .map(
                                  (member) => DropdownMenuItem<int>(
                                    value: member.userId,
                                    child: Text(
                                      '${member.fullName} • NIT ${member.nit}',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: formProvider.selectMember,
                            validator: (value) => value == null
                                ? 'Pilih anggota keluarga.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Nama Lengkap Pasangan',
                            controller: _spouseNameController,
                            icon: Icons.person_outline,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Tahun Lahir (opsional)',
                            controller: _birthYearController,
                            icon: Icons.calendar_today_outlined,
                            keyboardType: TextInputType.number,
                            validateYear: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Alamat (opsional)',
                            controller: _locationController,
                            icon: Icons.location_on_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  isSubmitting ||
                                      formProvider.selectedMemberId == null
                                  ? null
                                  : _saveFamily,
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Simpan Pasangan'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildGuidance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pilih anggota keluarga yang akan diberi pasangan. Pasangan tidak mempunyai NIT dan masuk ke cabang anggota yang dipilih.',
              style: TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _initialize,
            icon: const Icon(Icons.refresh),
            label: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
    bool validateYear = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) {
        final text = value?.trim() ?? '';
        if (isRequired && text.isEmpty) return '$label wajib diisi.';
        if (validateYear && text.isNotEmpty) {
          final year = int.tryParse(text);
          if (year == null || year < 1900 || year > DateTime.now().year) {
            return 'Masukkan tahun yang benar.';
          }
        }
        return null;
      },
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  InputDecoration _inputDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
