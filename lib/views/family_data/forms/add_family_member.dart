import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/family_contract.dart';
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
    final parentId = parent?.userId;
    final marriageId = _formProvider.selectedMarriageId;
    if (parentId == null || marriageId == null || !_formProvider.canSubmit) {
      _showError(
        _formProvider.contextError ??
            _formProvider.childCreationBlockingMessage ??
            _formProvider.marriageError ??
            (_formProvider.isBiological
                ? 'Pilih pernikahan terkait untuk anak kandung.'
                : 'Pilih pernikahan terkait untuk anak adopsi.'),
      );
      return;
    }

    final provider = context.read<UserProvider>();
    final createdChild = await provider.addChild(
      parentId: parentId,
      isBiological: _formProvider.isBiological,
      marriageId: marriageId,
      childData: UserData(
        fullName: _nameController.text.trim(),
        gender: _formProvider.gender,
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
        content: Text(
          createdChild.nit?.trim().isNotEmpty == true
              ? 'Anak berhasil ditambahkan. NIT ${createdChild.nit} sudah dibuat.'
              : 'Anak berhasil ditambahkan. NIT otomatis generate.',
        ),
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

    return ChangeNotifierProvider<FamilyMemberFormProvider>.value(
      value: _formProvider,
      child: Consumer<FamilyMemberFormProvider>(
        builder: (context, formProvider, child) {
          return Scaffold(
            backgroundColor: Config.background,
            appBar: AppBar(
              title: const Text(
                'Tambah Anak',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              leading: CustomBackButton(
                color: Config.white,
                onPressed: () => context.pop(),
              ),
              backgroundColor: Color(0xFF559260),
              elevation: 0,
            ),
            body:
                formProvider.isLoadingContext &&
                    formProvider.availableParents.isEmpty
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
                          if (formProvider.isLoadingContext)
                            const LinearProgressIndicator(),
                          if (formProvider.contextError != null) ...[
                            _buildErrorBox(
                              formProvider.contextError!,
                              onRetry: _initialize,
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildAdoptionChoice(formProvider),
                          const SizedBox(height: 16),
                          _buildMarriageContext(formProvider),
                          const SizedBox(height: 32),
                          _buildSystemNitInfo(),
                          const SizedBox(height: 20),
                          _buildTextField(
                            label: 'Nama Lengkap Anak',
                            controller: _nameController,
                            icon: Icons.person_outline,
                            isRequired: true,
                            enabled: formProvider.childDataInputsEnabled,
                          ),
                          const SizedBox(height: 16),
                          _buildGenderDropdown(formProvider),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Tahun Lahir (opsional)',
                            controller: _birthYearController,
                            icon: Icons.calendar_today_outlined,
                            keyboardType: TextInputType.number,
                            validateYear: true,
                            enabled: formProvider.childDataInputsEnabled,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Alamat (opsional)',
                            controller: _addressController,
                            icon: Icons.location_on_outlined,
                            maxLines: 3,
                            enabled: formProvider.childDataInputsEnabled,
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isSubmitting || !formProvider.canSubmit
                                  ? null
                                  : _saveData,
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
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
              'Anak otomatis dikaitkan ke pernikahan yang dipilih. Aktifkan toggle untuk menandai anak sebagai anak adopsi.',
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
      decoration:
          _inputDecoration(
            label: 'Anggota yang menjadi orang tua',
            icon: Icons.family_restroom,
          ).copyWith(
            helperText:
                'Pilih diri Anda, anak, atau cucu (maksimal 2 tingkat).',
            helperMaxLines: 2,
          ),
      items: provider.availableParents
          .map(
            (member) => DropdownMenuItem<int>(
              value: member.userId,
              child: Text('${member.fullName} • NIT ${member.nit}'),
            ),
          )
          .toList(),
      onChanged: provider.isLoadingContext
          ? null
          : (value) => provider.selectParent(
              value,
              userProvider: context.read<UserProvider>(),
            ),
      validator: (value) => value == null ? 'Pilih orang tua anak.' : null,
    );
  }

  Widget _buildAdoptionChoice(FamilyMemberFormProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black),
      ),
      child: SwitchListTile(
        value: provider.isAdopted,
        onChanged: provider.childDataInputsEnabled
            ? provider.setIsAdopted
            : null,
        title: const Text('Anak adopsi'),
        subtitle: const Text('Aktif = anak adopsi. Nonaktif = anak kandung.'),
        secondary: const Icon(Icons.link_outlined),
      ),
    );
  }

  Widget _buildMarriageContext(FamilyMemberFormProvider provider) {
    switch (provider.marriageLoadState) {
      case MarriageLoadState.initial:
      case MarriageLoadState.loading:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(),
            SizedBox(height: 8),
            Text('Memuat data pernikahan orang tua...'),
          ],
        );
      case MarriageLoadState.error:
        return _buildErrorBox(
          provider.marriageError ?? 'Data pernikahan gagal dimuat.',
          onRetry: () => provider.retryMarriages(
            userProvider: context.read<UserProvider>(),
          ),
          isBlocking: true,
        );
      case MarriageLoadState.success:
        if (provider.childCreationBlockingMessage != null) {
          return _buildRoleIntegrityBlock(
            provider.childCreationBlockingMessage!,
          );
        }
        if (provider.marriages.isEmpty) {
          return _buildErrorBox(
            'Pilih pernikahan terkait. Tambahkan pasangan terlebih dahulu jika belum ada.',
            onRetry: () => provider.retryMarriages(
              userProvider: context.read<UserProvider>(),
            ),
            showAddMarriage: true,
          );
        }
        return _buildMarriageDropdown(provider);
    }
  }

  Widget _buildMarriageDropdown(FamilyMemberFormProvider provider) {
    return DropdownButtonFormField<int>(
      key: ValueKey('marriage-${provider.selectedMarriageId}'),
      initialValue: provider.selectedMarriageId,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Pernikahan terkait',
        icon: Icons.favorite_outline,
      ),
      items: provider.marriages.map((marriage) {
        final spouseName =
            marriage.spouse?.fullName ?? 'Pasangan belum diketahui';
        return DropdownMenuItem<int>(
          value: marriage.marriageId,
          child: Text('Pasangan ${marriage.marriageOrder}: $spouseName'),
        );
      }).toList(),
      onChanged: provider.childDataInputsEnabled
          ? provider.selectMarriage
          : null,
      validator: (value) => value == null ? 'Pilih pernikahan terkait.' : null,
    );
  }

  Widget _buildSystemNitInfo() {
    return _buildInfoBox(
      'NIT anak otomatis dibuat setelah berhasil disimpan.',
      icon: Icons.badge_outlined,
    );
  }

  Widget _buildGenderDropdown(FamilyMemberFormProvider provider) {
    return DropdownButtonFormField<PersonGender>(
      key: ValueKey('gender-${provider.gender?.apiValue ?? 'empty'}'),
      initialValue: provider.gender,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Jenis kelamin anak',
        icon: Icons.wc_outlined,
      ),
      items: PersonGender.values
          .map(
            (gender) =>
                DropdownMenuItem(value: gender, child: Text(gender.label)),
          )
          .toList(),
      onChanged: provider.childDataInputsEnabled ? provider.selectGender : null,
      validator: (value) => value == null ? 'Pilih jenis kelamin anak.' : null,
    );
  }

  Widget _buildInfoBox(String message, {IconData icon = Icons.info_outline}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Config.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Config.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Config.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildRoleIntegrityBlock(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.block_outlined, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data keluarga perlu dirapikan terlebih dahulu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(
    String message, {
    required VoidCallback onRetry,
    bool showAddMarriage = false,
    bool isBlocking = true,
  }) {
    final parentId = _formProvider.selectedParentId;
    final color = isBlocking ? Colors.orange : Colors.blue;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Muat Ulang'),
              ),
              if (showAddMarriage && parentId != null)
                ElevatedButton.icon(
                  onPressed: () async {
                    await context.pushNamed(
                      'addFamily',
                      queryParameters: {'memberId': '$parentId'},
                    );
                    if (mounted) {
                      await _formProvider.retryMarriages(
                        userProvider: context.read<UserProvider>(),
                      );
                    }
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
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
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
