import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/auth_provider.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/foundation.dart';

enum GenderOnboardingState { idle, submitting, success, error }

class GenderOnboardingProvider extends ChangeNotifier {
  GenderOnboardingProvider({
    required UserProvider userProvider,
    required AuthProvider authProvider,
  }) : _userProvider = userProvider,
       _authProvider = authProvider;

  final UserProvider _userProvider;
  final AuthProvider _authProvider;

  PersonGender? _gender;
  GenderOnboardingState _state = GenderOnboardingState.idle;
  String? _errorMessage;

  PersonGender? get gender => _gender;
  GenderOnboardingState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _state == GenderOnboardingState.submitting;
  bool get canSubmit => _gender != null && !isSubmitting;

  void selectGender(PersonGender gender) {
    if (isSubmitting || _gender == gender) return;
    _gender = gender;
    _errorMessage = null;
    _state = GenderOnboardingState.idle;
    notifyListeners();
  }

  Future<bool> submit() async {
    final currentUser = _authProvider.currentUser;
    final gender = _gender;
    if (currentUser == null || gender == null || isSubmitting) return false;

    _state = GenderOnboardingState.submitting;
    _errorMessage = null;
    notifyListeners();

    final updatedUser = await _userProvider.updateProfile(
      data: UserData(
        userId: currentUser.userId,
        nit: currentUser.nit,
        familyTreeId: currentUser.familyTreeId,
        level: currentUser.level,
        parentId: currentUser.parentId,
        parentRelation: currentUser.parentRelation,
        fullName: currentUser.fullName,
        gender: gender,
        address: currentUser.address,
        birthYear: currentUser.birthYear,
        avatar: currentUser.avatar,
        avatarUrl: currentUser.avatarUrl,
        createdAt: currentUser.createdAt,
        updatedAt: currentUser.updatedAt,
      ),
    );

    if (updatedUser == null) {
      _state = GenderOnboardingState.error;
      _errorMessage =
          _userProvider.errorMessage ??
          'Gender gagal disimpan. Silakan coba lagi.';
      notifyListeners();
      return false;
    }

    _authProvider.updateUser(updatedUser);
    _state = GenderOnboardingState.success;
    notifyListeners();
    return true;
  }
}
