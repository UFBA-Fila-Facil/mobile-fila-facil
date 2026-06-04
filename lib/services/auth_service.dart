import 'dart:io';

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

  String _getGoogleClientId() {
    return '245106255438-8khsn9b98gmrsq36tianb2uo5tj26enb.apps.googleusercontent.com';
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn(
      clientId: _getGoogleClientId()
    ).signIn();
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
