import 'package:flutter/foundation.dart';

import '../core/exceptions/auth_exception_mapper.dart';
import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Drives every auth screen. Exposes a single [status] + [isLoading] +
/// [errorMessage] surface so screens stay declarative: they read state
/// and call methods, they never talk to Firebase directly.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  AuthProvider({AuthRepository? authRepository, UserRepository? userRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        _userRepository = userRepository ?? UserRepository() {
    _init();
  }

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void _init() {
    // Auto Login: react to Firebase's own persisted session instead of
    // rolling our own — this fires immediately with the cached user
    // on cold start, then again on any sign-in/out.
    _authRepository.authStateChanges.listen((fbUser) async {
      if (fbUser == null) {
        _user = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
      try {
        _user = await _userRepository.getUser(fbUser.uid);
      } catch (_) {
        _user = null;
      }
      _status = AuthStatus.authenticated;
      notifyListeners();
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      final user = await _authRepository.signUp(username: username, email: email, password: password);
      _user = user;
      _status = AuthStatus.authenticated;
      return true;
    } on AppAuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      final user = await _authRepository.signIn(email: email, password: password);
      _user = user;
      _status = AuthStatus.authenticated;
      return true;
    } on AppAuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _errorMessage = null;
    _setLoading(true);
    try {
      final user = await _authRepository.signInWithGoogle();
      _user = user;
      _status = AuthStatus.authenticated;
      return true;
    } on AppAuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      await _authRepository.sendPasswordResetEmail(email);
      return true;
    } on AppAuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Called by onboarding once category + goal are picked, so the
  /// in-memory user reflects it immediately without waiting on a
  /// Firestore round trip.
  void applyOnboarding({required String mainCategory, required String goal}) {
    if (_user == null) return;
    _user = _user!.copyWith(mainCategory: mainCategory, goal: goal);
    notifyListeners();
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }
}
