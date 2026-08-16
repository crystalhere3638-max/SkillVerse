import 'package:firebase_auth/firebase_auth.dart';

/// A user-friendly, UI-safe error. Screens should only ever render
/// [message] — never a raw exception or Firebase error code.
class AppAuthException implements Exception {
  final String message;
  const AppAuthException(this.message);

  @override
  String toString() => message;
}

/// Translates every FirebaseAuthException code (plus network/unknown
/// failures) into a friendly, non-technical message.
class AuthExceptionMapper {
  AuthExceptionMapper._();

  static AppAuthException map(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return const AppAuthException('No account found with this email.');
        case 'wrong-password':
        case 'invalid-credential':
          return const AppAuthException('Incorrect email or password.');
        case 'email-already-in-use':
          return const AppAuthException('An account already exists with this email.');
        case 'invalid-email':
          return const AppAuthException('That email address looks invalid.');
        case 'weak-password':
          return const AppAuthException('Choose a stronger password.');
        case 'user-disabled':
          return const AppAuthException('This account has been disabled.');
        case 'too-many-requests':
          return const AppAuthException('Too many attempts. Please wait and try again.');
        case 'network-request-failed':
          return const AppAuthException('No internet connection. Check your network and try again.');
        case 'operation-not-allowed':
          return const AppAuthException('This sign-in method is not enabled.');
        case 'account-exists-with-different-credential':
          return const AppAuthException('An account already exists with a different sign-in method.');
        case 'requires-recent-login':
          return const AppAuthException('Please log in again to continue.');
        case 'popup-closed-by-user':
        case 'sign_in_canceled':
        case 'canceled':
          return const AppAuthException('Sign-in was cancelled.');
        default:
          return AppAuthException(error.message ?? 'Something went wrong. Please try again.');
      }
    }

    final text = error.toString().toLowerCase();
    if (text.contains('network') || text.contains('socket')) {
      return const AppAuthException('No internet connection. Check your network and try again.');
    }
    if (text.contains('cancel')) {
      return const AppAuthException('Sign-in was cancelled.');
    }
    return const AppAuthException('Something went wrong. Please try again.');
  }
}
