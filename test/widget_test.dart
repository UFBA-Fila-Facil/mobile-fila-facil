// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_fila_facil/screens/login_screen.dart';
import 'package:mobile_fila_facil/services/auth_service.dart';

class _FakeTestAuthService implements AuthService {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => const Stream<User?>.empty();

  @override
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return _FakeUserCredential();
  }

  @override
  Future<UserCredential> registerWithEmailAndPassword(String displayName, String email, String password) async {
    return _FakeUserCredential();
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    return _FakeUserCredential();
  }

  @override
  Future<void> signOut() async {}
}

class _FakeUserCredential extends Fake implements UserCredential {}

void main() {
  testWidgets('Login screen renders with required fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(authService: _FakeTestAuthService()),
      ),
    );

    expect(find.text('Usuário'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Google'), findsOneWidget);
    expect(find.text('Cadastre-se'), findsOneWidget);
  });
}
