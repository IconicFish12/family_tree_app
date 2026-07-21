import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';

class FamilyEditFormProvider extends ChangeNotifier {
  FamilyEditFormProvider({
    required String initialName,
    String? initialAddress,
    String? initialBirthYear,
  }) : nameController = TextEditingController(text: initialName),
       addressController = TextEditingController(text: initialAddress ?? ''),
       birthYearController = TextEditingController(
         text: initialBirthYear ?? '',
       );

  final formKey = GlobalKey<FormState>();
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController birthYearController;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isDisposed = false;

  String? validateName(String? value) {
    if (value?.trim().isEmpty ?? true) {
      return 'Nama wajib diisi.';
    }
    return null;
  }

  String? validateOptionalYear(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final year = int.tryParse(text);
    if (year == null || year < 1900 || year > DateTime.now().year) {
      return 'Masukkan tahun yang benar.';
    }
    return null;
  }

  Future<bool> updateMember({
    required UserProvider userProvider,
    required int memberId,
  }) {
    return _submit(
      action: () => userProvider.updateFamilyMember(
        memberId: memberId,
        memberData: _formData,
      ),
      fallbackError: 'Data anggota gagal diubah.',
      userProvider: userProvider,
    );
  }

  Future<bool> updateSpouse({
    required UserProvider userProvider,
    required int memberId,
    required int marriageId,
  }) {
    return _submit(
      action: () => userProvider.updateMarriage(
        marriageId: marriageId,
        memberId: memberId,
        spouseData: _formData,
      ),
      fallbackError: 'Data pasangan gagal diubah.',
      userProvider: userProvider,
    );
  }

  UserData get _formData => UserData(
    fullName: nameController.text.trim(),
    address: _emptyToNull(addressController.text),
    birthYear: _emptyToNull(birthYearController.text),
  );

  Future<bool> _submit({
    required Future<bool> Function() action,
    required String fallbackError,
    required UserProvider userProvider,
  }) async {
    if (_isSubmitting || !(formKey.currentState?.validate() ?? false)) {
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _notifyIfMounted();

    final success = await action();
    if (!success) {
      _errorMessage = userProvider.errorMessage ?? fallbackError;
    }
    _isSubmitting = false;
    _notifyIfMounted();
    return success;
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _notifyIfMounted() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    nameController.dispose();
    addressController.dispose();
    birthYearController.dispose();
    super.dispose();
  }
}
