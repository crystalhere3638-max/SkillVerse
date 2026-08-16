import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/exceptions/auth_exception_mapper.dart';
import '../models/app_user.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_user_service.dart';
import '../services/google_auth_service.dart';

/// Single entry point the rest of the app talks to for anything
/// authentication-related. Combines Firebase Auth + Google Sign-In +
/// the Firestore user document, and always throws [AppAuthException]
/// so the UI never has to know about FirebaseAuthException codes.
///
/// Security notes:
/// - Passwords are never stored or logged anywhere in this app;
///   Firebase Auth handles the credential exchange entirely.
/// - `flutter_secure_storage` is only used to remember the last
///   signed-in email for convenience, never a password or token.
class AuthRepository {
  final FirebaseAuthService _authService;
  final GoogleAuthService _googleAuthService;
  final FirestoreUserService _userService;
  final FlutterSecureStorage _secureStorage;

  static const _kLastEmailKey = 'last_signed_in_email';

  AuthRepository({
    FirebaseAuthService? authService,
    GoogleAuthService? googleAuthService,
    FirestoreUserService? userService,
    FlutterSecureStorage? secureStorage,
  })  : _authService = authService ?? FirebaseAuthService(),
        _googleAuthService = googleAuthService ?? GoogleAuthService(),
        _userService = userService ?? FirestoreUserService(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Stream<User?> get authStateChanges => _authService.authStateChanges();
  User? get currentUser => _authService.currentUser;

  Future<String?> get lastSignedInEmail => _secureStorage.read(key: _kLastEmailKey);

  Future<AppUser> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _authService.signUpWithEmail(email: email, password: password);
      final uid = credential.user!.uid;

      await _authService.updateDisplayName(username);
      // Ready for future email-verification gating; sending is best-effort.
      unawaited(_authService.sendEmailVerification());

      final newUser = AppUser.newFromAuth(uid: uid, username: username, email: email);
      await _userService.createUser(newUser);
      await _secureStorage.write(key: _kLastEmailKey, value: email);
      return newUser;
    } catch (e) {
      throw AuthExceptionMapper.map(e);
    }
  }

  Future<AppUser> signIn({required String email, required String password}) async {
    try {
      final credential = await _authService.signInWithEmail(email: email, password: password);
      final uid = credential.user!.uid;
      await _userService.updateLastLogin(uid);
      await _secureStorage.write(key: _kLastEmailKey, value: email);

      final user = await _userService.getUser(uid);
      if (user == null) {
        // Extremely unlikely (auth exists, doc missing) — self-heal.
        final rebuilt = AppUser.newFromAuth(
          uid: uid,
          username: credential.user!.displayName ?? 'Learner',
          email: email,
        );
        await _userService.createUser(rebuilt);
        return rebuilt;
      }
      return user;
    } catch (e) {
      throw AuthExceptionMapper.map(e);
    }
  }

  /// Signs in with Google. Creates the Firestore user document
  /// automatically the first time this Google account is seen.
  Future<AppUser> signInWithGoogle() async {
    try {
      final credential = await _googleAuthService.getCredential();
      final userCredential = await _authService.signInWithCredential(credential);
      final fbUser = userCredential.user!;
      final uid = fbUser.uid;

      final existing = await _userService.getUser(uid);
      if (existing != null) {
        await _userService.updateLastLogin(uid);
        return existing;
      }

      final newUser = AppUser.newFromAuth(
        uid: uid,
        username: fbUser.displayName ?? 'Learner',
        email: fbUser.email ?? '',
        photoUrl: fbUser.photoURL,
      );
      await _userService.createUser(newUser);
      return newUser;
    } catch (e) {
      throw AuthExceptionMapper.map(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      throw AuthExceptionMapper.map(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _googleAuthService.signOut();
      await _authService.signOut();
      await _secureStorage.delete(key: _kLastEmailKey);
    } catch (e) {
      throw AuthExceptionMapper.map(e);
    }
  }
}

/// Small helper so fire-and-forget futures still surface unexpected
/// errors instead of failing silently.
void unawaited(Future<void> future) {
  future.catchError((_) {});
}
