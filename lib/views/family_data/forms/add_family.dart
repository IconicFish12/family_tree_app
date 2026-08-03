import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/family_contract.dart';
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

  @override
  void dispose() {
    _spouseNameController.dispose();
    _locationController.dispose();
    _birthYearController.dispose();
    _formProvider.dispose();
    super.dispose();
  }

  Future<void> _saveFamily() async {
    final memberId = _formProvider.selectedMemberId;
    final memberRole = _formProvider.memberRole;
    if (memberId == null || memberRole == null || !_formProvider.canSubmit) {
      _showError(
        _formProvider.blockingMessage ??
            _formProvider.roleCompatibilityError ??
            (memberId == null
                ? 'Pilih anggota keluarga terlebih dahulu.'
                : 'Pilih peran anggota dalam pernikahan.'),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();
    final createdMarriage = await userProvider.addSpouse(
      memberId: memberId,
      memberRole: memberRole,
      spouseData: UserData(
        fullName: _spouseNameController.text.trim(),
        gender: _formProvider.spouseGender,
        address: _emptyToNull(_locationController.text),
        birthYear: _emptyToNull(_birthYearController.text),
      ),
    );

    if (!mounted) return;
    if (createdMarriage == null) {
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
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              backgroundColor: Color(0xFF559260),
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
                            onChanged: (value) => formProvider.selectMember(
                              value,
                              userProvider: context.read<UserProvider>(),
                            ),
                            validator: (value) => value == null
                                ? 'Pilih anggota keluarga.'
                                : null,
                          ),
                          const SizedBox(height: 32),
                          if (formProvider.isLoadingMemberContext) ...[
                            const LinearProgressIndicator(),
                            const SizedBox(height: 8),
                            const Text(
                              'Memeriksa detail dan riwayat pernikahan anggota...',
                              style: TextStyle(height: 1.4),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (formProvider.memberDetailError != null) ...[
                            _buildMemberDetailWarning(
                              formProvider.memberDetailError!,
                              onRetry: () =>
                                  formProvider.retrySelectedMemberContext(
                                    userProvider: context.read<UserProvider>(),
                                  ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (formProvider.marriageError != null) ...[
                            _buildBlockingNotice(
                              formProvider.marriageError!,
                              onRetry: () =>
                                  formProvider.retrySelectedMemberContext(
                                    userProvider: context.read<UserProvider>(),
                                  ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (formProvider.policyGuidanceMessage != null) ...[
                            _buildPolicyNotice(
                              formProvider.policyGuidanceMessage!,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (formProvider.marriageError == null &&
                              formProvider.hasBlockingIssue &&
                              formProvider.blockingMessage != null) ...[
                            _buildBlockingNotice(formProvider.blockingMessage!),
                            const SizedBox(height: 16),
                          ],
                          _buildMemberRoleDropdown(formProvider),
                          const SizedBox(height: 32),
                          _buildTextField(
                            label: 'Nama Lengkap Pasangan',
                            controller: _spouseNameController,
                            icon: Icons.person_outline,
                            isRequired: true,
                            enabled: formProvider.spouseInputsEnabled,
                          ),
                          const SizedBox(height: 16),
                          _buildGenderDropdown(formProvider),
                          if (formProvider.roleCompatibilityError != null) ...[
                            const SizedBox(height: 12),
                            _buildCompatibilityWarning(
                              formProvider.roleCompatibilityError!,
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Tahun Lahir (opsional)',
                            controller: _birthYearController,
                            icon: Icons.calendar_today_outlined,
                            keyboardType: TextInputType.number,
                            validateYear: true,
                            enabled: formProvider.spouseInputsEnabled,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Alamat (opsional)',
                            controller: _locationController,
                            icon: Icons.location_on_outlined,
                            maxLines: 3,
                            enabled: formProvider.spouseInputsEnabled,
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isSubmitting || !formProvider.canSubmit
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
          Icon(Icons.warning_amber_rounded, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PENTING sebelum memilih peran',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  '1. Pilih status hubungan anggota yang namanya dipilih.\n'
                  '2. Suami bisa mempunyai beberapa Istri. Istri hanya bisa mempunyai satu Suami.\n'
                  '3. Pilihan pertama akan dikunci. Untuk menggantinya, Harus menghapus data anak-anak dan pasangan terlebih dahulu.',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRoleDropdown(MarriageFormProvider provider) {
    final memberGender = provider.selectedMemberDetail?.gender;
    final memberName = provider.selectedMember?.fullName ?? 'anggota ini';
    final String roleGuidance;
    if (provider.isLoadingMemberContext) {
      roleGuidance = 'Tunggu sampai pemeriksaan riwayat selesai.';
    } else if (provider.isRoleLocked) {
      roleGuidance =
          'Ini untuk $memberName, bukan pasangan baru. Status hubungan mengikuti riwayat dan tidak dapat diubah.';
    } else if (provider.canChooseRole) {
      roleGuidance =
          'Ini untuk $memberName, bukan pasangan baru. Pilih dengan teliti';
    } else {
      roleGuidance = 'Peran tidak dapat dipilih sampai masalah diselesaikan.';
    }
    final genderGuidance = memberGender == null
        ? ''
        : ' Gender anggota: ${memberGender.label}.';
    return DropdownButtonFormField<MarriageRole>(
      key: ValueKey('member-role-${provider.memberRole?.apiValue ?? 'empty'}'),
      initialValue: provider.memberRole,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Status hubungan setelah pernikahan',
        icon: Icons.people_outline,
      ).copyWith(helperText: '$roleGuidance$genderGuidance', helperMaxLines: 3),
      items: MarriageRole.values
          .map((role) => DropdownMenuItem(value: role, child: Text(role.label)))
          .toList(),
      onChanged: provider.canChooseRole ? provider.selectMemberRole : null,
      validator: (value) =>
          value == null ? 'Pilih peran anggota dalam pernikahan.' : null,
    );
  }

  Widget _buildGenderDropdown(MarriageFormProvider provider) {
    return DropdownButtonFormField<String>(
      key: ValueKey(
        'spouse-gender-${provider.spouseGender?.apiValue ?? 'empty'}',
      ),
      initialValue: provider.spouseGender?.apiValue ?? '',
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Jenis kelamin pasangan (opsional)',
        icon: Icons.wc_outlined,
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('Tidak diisi')),
        ...PersonGender.values.map(
          (gender) => DropdownMenuItem(
            value: gender.apiValue,
            child: Text(gender.label),
          ),
        ),
      ],
      onChanged: provider.spouseInputsEnabled
          ? (value) => provider.selectSpouseGender(_genderFromApiValue(value))
          : null,
    );
  }

  PersonGender? _genderFromApiValue(String? value) {
    for (final gender in PersonGender.values) {
      if (gender.apiValue == value) return gender;
    }
    return null;
  }

  Widget _buildMemberDetailWarning(
    String message, {
    required VoidCallback onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityWarning(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_outlined, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

  Widget _buildPolicyNotice(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.policy_outlined, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildBlockingNotice(String message, {VoidCallback? onRetry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.block_outlined, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: const TextStyle(height: 1.4)),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
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
