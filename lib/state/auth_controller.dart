import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._service);

  final AuthService _service;

  AppUser? _user;
  bool _initializing = true;
  bool _busy = false;
  String? _error;

  AppUser? get user => _user;
  bool get initializing => _initializing;
  bool get busy => _busy;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<void> restoreSession() async {
    _initializing = true;
    notifyListeners();
    try {
      _user = await _service.restoreSession();
    } catch (_) {
      _user = null;
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.signIn(email: email, password: password);
      return true;
    } on AppException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      _error = 'Terjadi kesalahan: $error';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      return true;
    } on AppException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      _error = 'Terjadi kesalahan: $error';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}
