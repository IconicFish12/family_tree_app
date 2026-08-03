import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/family_edit_form_provider.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum FamilyEditMode { member, spouse }

Future<bool?> showFamilyEditDialog({
  required BuildContext context,
  required FamilyEditMode mode,
  required UserData initialData,
  required int memberId,
  int? marriageId,
}) {
  assert(mode == FamilyEditMode.member || marriageId != null);

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => ChangeNotifierProvider(
      create: (_) => FamilyEditFormProvider(
        initialName: initialData.fullName ?? '',
        initialGender: initialData.gender,
        initialAddress: initialData.address,
        initialBirthYear: initialData.birthYear,
      ),
      child: FamilyEditDialog(
        mode: mode,
        memberId: memberId,
        marriageId: marriageId,
        nit: initialData.nit,
      ),
    ),
  );
}

class FamilyEditDialog extends StatelessWidget {
  const FamilyEditDialog({
    super.key,
    required this.mode,
    required this.memberId,
    this.marriageId,
    this.nit,
  });

  final FamilyEditMode mode;
  final int memberId;
  final int? marriageId;
  final String? nit;

  bool get _isMember => mode == FamilyEditMode.member;

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyEditFormProvider>(
      builder: (context, formProvider, child) {
        return PopScope(
          canPop: !formProvider.isSubmitting,
          child: AlertDialog(
            title: Text(_isMember ? 'Edit Data Anggota' : 'Edit Data Pasangan'),
            content: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: formProvider.formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isMember) ...[
                      TextFormField(
                        initialValue: nit ?? '-',
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'NIT',
                          helperText: 'NIT tidak dapat diubah.',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: formProvider.nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                      ),
                      validator: formProvider.validateName,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: formProvider.gender?.apiValue ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Gender (opsional)',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Tidak diisi'),
                        ),
                        ...PersonGender.values.map(
                          (gender) => DropdownMenuItem<String>(
                            value: gender.apiValue,
                            child: Text(gender.label),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        final gender = value == null || value.isEmpty
                            ? null
                            : PersonGender.values.firstWhere(
                                (item) => item.apiValue == value,
                              );
                        formProvider.selectGender(gender);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: formProvider.birthYearController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Tahun Lahir (opsional)',
                      ),
                      validator: formProvider.validateOptionalYear,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: formProvider.addressController,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Alamat (opsional)',
                      ),
                    ),
                    if (formProvider.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          formProvider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: formProvider.isSubmitting
                    ? null
                    : () => _close(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: formProvider.isSubmitting
                    ? null
                    : () => _save(context, formProvider),
                child: formProvider.isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save(
    BuildContext context,
    FamilyEditFormProvider formProvider,
  ) async {
    final userProvider = context.read<UserProvider>();
    final success = _isMember
        ? await formProvider.updateMember(
            userProvider: userProvider,
            memberId: memberId,
          )
        : await formProvider.updateSpouse(
            userProvider: userProvider,
            memberId: memberId,
            marriageId: marriageId!,
          );

    if (success && context.mounted) {
      _close(context, true);
    }
  }

  void _close(BuildContext context, bool changed) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(changed);
  }
}
