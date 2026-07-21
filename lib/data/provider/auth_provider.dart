import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/core/session_storage.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/repository/auth_repository.dart';

enum AuthStatus { initializing, unauthenticated, authenticating, authenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SessionStorage _sessionStorage;
  final FutureOr<void> Function()? _onSessionCleared;

  AuthProvider(
    this._authRepository,
    this._sessionStorage, {
    FutureOr<void> Function()? onSessionCleared,
  }) : _onSessionCleared = onSessionCleared {
    Config.registerUnauthorizedHandler(handleUnauthorized);
    unawaited(initializeSession());
  }

  AuthStatus _status = AuthStatus.initializing;
  AuthStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserData? _currentUser;
  UserData? get currentUser => _currentUser;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> initializeSession() async {
    try {
      _status = AuthStatus.initializing;
      _errorMessage = null;
      notifyListeners();

      final savedToken = await _sessionStorage.getAccessToken();
      if (savedToken == null || savedToken.isEmpty) {
        await _clearLocalSession(notify: false);
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      Config.setAccessToken(savedToken);

      final profileResult = await _authRepository.getProfile();
      if (profileResult.isLeft()) {
        await _clearLocalSession(notify: false);
        _status = AuthStatus.unauthenticated;
      } else {
        profileResult.fold((_) => null, (profile) {
          _currentUser = profile;
          _status = AuthStatus.authenticated;
        });
      }
    } catch (_) {
      await _clearLocalSession(notify: false);
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> login(String nit, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    final loginResult = await _authRepository.login(
      nit: nit.trim(),
      password: password.trim(),
      deviceName: defaultTargetPlatform.name,
    );

    final success = await loginResult.fold(
      (failure) async {
        _errorMessage = failure.message;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      },
      (token) async {
        Config.setAccessToken(token);
        await _sessionStorage.saveAccessToken(token);

        final profileResult = await _authRepository.getProfile();
        return profileResult.fold(
          (failure) async {
            await _clearLocalSession(notify: false);
            _errorMessage = failure.message;
            _status = AuthStatus.unauthenticated;
            notifyListeners();
            return false;
          },
          (profile) async {
            _currentUser = profile;
            _status = AuthStatus.authenticated;
            notifyListeners();
            return true;
          },
        );
      },
    );

    return success;
  }

  Future<void> logout() async {
    await _authRepository.logout();
    await _clearLocalSession();
  }

  Future<void> handleUnauthorized(String reason) async {
    _errorMessage = reason;
    await _clearLocalSession();
  }

  void updateUser(UserData updatedUser) {
    final current = _currentUser;
    if (current == null) return;

    dynamic nextAvatar = current.avatar;
    if (updatedUser.avatar != null) {
      nextAvatar = updatedUser.avatar;
    }

    _currentUser = current.copyWith(
      fullName: updatedUser.fullName ?? current.fullName,
      address: updatedUser.address ?? current.address,
      birthYear: updatedUser.birthYear ?? current.birthYear,
      avatar: nextAvatar,
    );
    notifyListeners();
  }

  Future<void> _clearLocalSession({bool notify = true}) async {
    _currentUser = null;
    Config.setAccessToken(null);
    await _sessionStorage.clear();
    await _onSessionCleared?.call();
    _status = AuthStatus.unauthenticated;
    if (notify) {
      notifyListeners();
    }
  }
}
