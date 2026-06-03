import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_fila_facil/screens/login_screen.dart';
import 'package:mobile_fila_facil/screens/register_screen.dart';
import 'package:mobile_fila_facil/services/auth_service.dart';

class FakeAuthService extends Fake implements AuthService {
  bool signInWithEmailCalled = false;
  bool signInWithGoogleCalled = false;
  bool registerWithEmailCalled = false;

  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => const Stream<User?>.empty();

  @override
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    signInWithEmailCalled = true;
    return _FakeUserCredential();
  }

  @override
  Future<UserCredential> registerWithEmailAndPassword(String displayName, String email, String password) async {
    registerWithEmailCalled = true;
    return _FakeUserCredential();
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    signInWithGoogleCalled = true;
    return _FakeUserCredential();
  }

  @override
  Future<void> signOut() async {}
}

class _FakeUserCredential extends Fake implements UserCredential {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUserCredential());
  });

  testWidgets('Login screen shows form fields and actions', (WidgetTester tester) async {
    final authService = FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(authService: authService),
      ),
    );

    expect(find.text('Usuário'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Google'), findsOneWidget);
    expect(find.text('Cadastre-se'), findsOneWidget);
  });

  testWidgets('Cadastre-se button navigates to registration screen', (WidgetTester tester) async {
    final authService = FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          RegisterScreen.routeName: (context) => RegisterScreen(authService: authService),
        },
        home: LoginScreen(authService: authService),
      ),
    );

    await tester.ensureVisible(find.text('Cadastre-se'));
    await tester.tap(find.text('Cadastre-se'));
    await tester.pumpAndSettle();

    expect(find.text('Crie sua conta'), findsOneWidget);
    expect(find.text('Cadastrar com o Google'), findsOneWidget);
  });

  testWidgets('Entrar button calls email/password login', (WidgetTester tester) async {
    final authService = FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(authService: authService),
      ),
    );

    await tester.enterText(find.bySemanticsLabel('Usuário'), 'teste@exemplo.com');
    await tester.enterText(find.bySemanticsLabel('Senha'), 'senha123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(authService.signInWithEmailCalled, isTrue);
  });

  testWidgets('Register screen shows form and Google signup', (WidgetTester tester) async {
    final authService = FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(authService: authService),
      ),
    );

    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Cadastrar com o Google'), findsOneWidget);
    expect(find.text('Cadastrar'), findsOneWidget);
  });
}
