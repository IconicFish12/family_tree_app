import 'package:family_tree_app/data/models/login_model.dart';
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

  // Menyimpan data user yang sedang login
  Data? _currentUser;
  Data? get currentUser => _currentUser;

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
        // TODO: Jika nanti ada token, simpan ke SharedPreferences di sini
        // await _saveToken(loginModel.token); 
        
        _state = ViewState.success;
        notifyListeners();
        return true;
      },
    );
  }
}