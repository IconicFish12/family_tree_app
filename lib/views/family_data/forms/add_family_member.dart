import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/auth_provider.dart';
import 'package:family_tree_app/data/provider/family_member_form_provider.dart';
import 'package:family_tree_app/data/provider/tree_provider.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AddFamilyMemberPage extends StatefulWidget {
  final int? initialParentId;

  const AddFamilyMemberPage({super.key, this.initialParentId});

  @override
  State<AddFamilyMemberPage> createState() => _AddFamilyMemberPageState();
}

class _AddFamilyMemberPageState extends State<AddFamilyMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthYearController = TextEditingController();
  final FamilyMemberFormProvider _formProvider = FamilyMemberFormProvider();

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
      initialParentId: widget.initialParentId,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _birthYearController.dispose();
    _formProvider.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    final parent = _formProvider.selectedParent;
    final marriageId = _formProvider.selectedMarriageId;
    if (parent?.userId == null || parent!.nit.trim().isEmpty || marriageId == null || _formProvider.generatedNit == null) {
      _showError(_formProvider.contextError ?? 'NIT belum dapat dibuat. Silakan muat ulang data dan coba kembali.');
      return;
    }

    final provider = context.read<UserProvider>();
    final createdChild = await provider.addChild(
      parentId: parent.userId!,
      parentNit: parent.nit,
      marriageId: marriageId,
      childData: UserData(
        fullName: _nameController.text.trim(),
        address: _emptyToNull(_addressController.text),
        birthYear: _emptyToNull(_birthYearController.text),
      ),
    );

    if (!mounted) return;
    if (createdChild == null) {
      _showError(provider.errorMessage ?? 'Gagal menyimpan data anak.');
      return;
    }

    await context.read<TreeProvider>().refreshCurrentTree();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Anak berhasil ditambahkan dengan NIT ${createdChild.nit ?? _formProvider.generatedNit}.'),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<UserProvider, bool>((provider) => provider.isSubmitting);

    return ChangeNotifierProvider<FamilyMemberFormProvider>.value(
      value: _formProvider,
      child: Consumer<FamilyMemberFormProvider>(
        builder: (context, formProvider, child) {
          return Scaffold(
            backgroundColor: Config.background,
            appBar: AppBar(
              title: const Text(
                'Tambah Anak',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              centerTitle: true,
              leading: CustomBackButton(onPressed: () => context.pop()),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            body: formProvider.isLoadingContext && formProvider.availableParents.isEmpty
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
                          _buildParentDropdown(formProvider),
                          const SizedBox(height: 16),
                          if (formProvider.isLoadingContext) const LinearProgressIndicator(),
                          if (formProvider.contextError != null) ...[
                            _buildErrorBox(formProvider.contextError!),
                            const SizedBox(height: 16),
                          ],
                          if (formProvider.marriages.isNotEmpty) ...[
                            _buildMarriageDropdown(formProvider),
                            const SizedBox(height: 16),
                          ],
                          _buildGeneratedNit(formProvider.generatedNit),
                          const SizedBox(height: 20),
                          _buildTextField(
                            label: 'Nama Lengkap Anak',
                            controller: _nameController,
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
                            controller: _addressController,
                            icon: Icons.location_on_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  isSubmitting ||
                                      formProvider.isLoadingContext ||
                                      formProvider.generatedNit == null ||
                                      formProvider.selectedMarriageId == null
                                  ? null
                                  : _saveData,
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('Simpan Anak'),
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
        color: Config.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Config.primary.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Config.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pilih orang tua dan pasangannya. NIT anak dihitung otomatis dari seluruh anak langsung milik orang tua tersebut.',
              style: TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentDropdown(FamilyMemberFormProvider provider) {
    return DropdownButtonFormField<int>(
      key: ValueKey('parent-${provider.selectedParentId}'),
      initialValue: provider.selectedParentId,
      isExpanded: true,
      decoration: _inputDecoration(label: 'Anggota yang menjadi orang tua', icon: Icons.family_restroom),
      items: provider.availableParents
          .map(
            (member) => DropdownMenuItem<int>(value: member.userId, child: Text('${member.fullName} • NIT ${member.nit}')),
          )
          .toList(),
      onChanged: provider.isLoadingContext
          ? null
          : (value) => provider.selectParent(value, userProvider: context.read<UserProvider>()),
      validator: (value) => value == null ? 'Pilih orang tua anak.' : null,
    );
  }

  Widget _buildMarriageDropdown(FamilyMemberFormProvider provider) {
    return DropdownButtonFormField<int>(
      key: ValueKey('marriage-${provider.selectedMarriageId}'),
      initialValue: provider.selectedMarriageId,
      isExpanded: true,
      decoration: _inputDecoration(label: 'Pasangan asal anak', icon: Icons.favorite_outline),
      items: provider.marriages.map((marriage) {
        final spouseName = marriage.spouse?.fullName ?? 'Pasangan belum diketahui';
        return DropdownMenuItem<int>(
          value: marriage.marriageId,
          child: Text('Pasangan ${marriage.marriageOrder}: $spouseName'),
        );
      }).toList(),
      onChanged: provider.selectMarriage,
      validator: (value) => value == null ? 'Pilih pasangan asal anak.' : null,
    );
  }

  Widget _buildGeneratedNit(String? generatedNit) {
    return TextFormField(
      key: ValueKey('nit-$generatedNit'),
      initialValue: generatedNit ?? '',
      readOnly: true,
      decoration: _inputDecoration(label: 'NIT Anak', icon: Icons.badge_outlined).copyWith(
        helperText: generatedNit == null ? 'NIT belum dapat dibuat.' : 'NIT dibuat otomatis dan tidak dapat diubah.',
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    final parentId = _formProvider.selectedParentId;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(onPressed: _initialize, icon: const Icon(Icons.refresh), label: const Text('Muat Ulang')),
              if (_formProvider.hasNoMarriage && parentId != null)
                ElevatedButton.icon(
                  onPressed: () async {
                    await context.pushNamed('addFamily', queryParameters: {'memberId': '$parentId'});
                    if (mounted) await _initialize();
                  },
                  icon: const Icon(Icons.favorite_outline),
                  label: const Text('Tambah Pasangan'),
                ),
            ],
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
