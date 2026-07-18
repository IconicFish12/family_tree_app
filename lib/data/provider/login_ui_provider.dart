import 'package:flutter/foundation.dart';

class LoginUiProvider extends ChangeNotifier {
  bool _obscurePassword = true;

  bool get obscurePassword => _obscurePassword;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }
}
