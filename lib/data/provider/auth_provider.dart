import 'package:family_tree_app/data/models/login_model.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/repository/auth_repository.dart';
import 'package:flutter/material.dart';

enum ViewState { initial, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);

  ViewState _state = ViewState.initial;
  ViewState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Data? _currentUser;
  Data? get currentUser => _currentUser;

  void updateUser(UserData updatedUser) {
    if (_currentUser == null) return;

    debugPrint('[AuthProvider] Updating user with: ${updatedUser.toJson()}');

    dynamic newAvatar = _currentUser!.avatar;
    if (updatedUser.avatar != null) {
      if (updatedUser.avatar is String) {
        newAvatar = updatedUser.avatar;
      }
    }

    _currentUser = _currentUser!.copyWith(
      fullName: updatedUser.fullName ?? _currentUser!.fullName,
      address: updatedUser.address ?? _currentUser!.address,
      birthYear: updatedUser.birthYear ?? _currentUser!.birthYear,
      avatar: newAvatar,
    );

    debugPrint(
      '[AuthProvider] Updated currentUser: fullName=${_currentUser!.fullName}, avatar=${_currentUser!.avatar}',
    );
    notifyListeners();
  }

  Future<bool> login(String familyTreeId, String password) async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.login(familyTreeId, password);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _state = ViewState.error;
        notifyListeners();
        return false;
      },
      (loginModel) {
        _currentUser = loginModel.data;

        _state = ViewState.success;
        notifyListeners();
        return true;
      },
    );
  }
}
