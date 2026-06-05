import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthService {
  User? get currentUser;

  Stream<User?> authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword(String email, String password);

  Future<UserCredential> registerWithEmailAndPassword(
    String displayName,
    String email,
    String password,
  );

  Future<void> sendPasswordResetEmail(String email);

  Future<UserCredential> signInWithGoogle();

  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserCredential> registerWithEmailAndPassword(
    String displayName,
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      await credential.user!.updateDisplayName(displayName);
      await credential.user!.reload();
    }

    return credential;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<GoogleSignInAccount?> _getGoogleSignIn() {
    if (kIsWeb) {
      return GoogleSignIn(
        clientId: '245106255438-83acpm3pu2o53o7j6uvmp2s20tacv2mt.apps.googleusercontent.com'
      ).signIn();
    }
    return GoogleSignIn().signIn();
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _getGoogleSignIn();
    if (googleUser == null) {
      throw Exception('Login com Google cancelado.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }
}
