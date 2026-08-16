import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps the Google Sign-In SDK and converts its result into a
/// Firebase [AuthCredential]. Throws a plain [Exception] with code
/// `sign_in_canceled` when the user backs out of the picker, which
/// [AuthExceptionMapper] turns into a friendly, non-alarming message.
class GoogleAuthService {
  final GoogleSignIn _googleSignIn;

  GoogleAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email']);

  Future<AuthCredential> getCredential() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw FirebaseAuthException(
        code: 'sign_in_canceled',
        message: 'Sign-in was cancelled.',
      );
    }

    final googleAuth = await account.authentication;
    return GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
