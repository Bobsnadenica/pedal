import 'package:flutter/material.dart';

class SessionService extends ChangeNotifier {
  bool _loggedIn = false;

  bool get isLoggedIn => _loggedIn;

  Future<bool> login(String user, String pass) async {
    if (user == 'test' && pass == 'test') {
      _loggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _loggedIn = false;
    notifyListeners();
  }
}