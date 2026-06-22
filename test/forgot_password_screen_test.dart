import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_fila_facil/screens/forgot_password_screen.dart';
import 'package:mobile_fila_facil/services/auth_service.dart';

// ── Fake ──────────────────────────────────────────────────────────────────────

class FakeAuthService extends Fake implements AuthService {
  String? lastResetEmail;
  bool shouldThrow = false;

  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => const Stream.empty();

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (shouldThrow) throw Exception('Reset failed');
    lastResetEmail = email;
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> registerWithEmailAndPassword(
      String displayName, String email, String password) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ForgotPasswordScreen — estrutura', () {
    testWidgets('exibe campo de email e botão de envio', (tester) async {
      final auth = FakeAuthService();
      await tester.pumpWidget(
        MaterialApp(home: ForgotPasswordScreen(authService: auth)),
      );

      expect(find.text('Esqueceu a senha?'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.text('Enviar link de recuperação'), findsOneWidget);
      expect(find.text('Voltar para login'), findsOneWidget);
    });
  });

  group('ForgotPasswordScreen — validação', () {
    testWidgets('exibe erro quando email está vazio', (tester) async {
      final auth = FakeAuthService();
      await tester.pumpWidget(
        MaterialApp(home: ForgotPasswordScreen(authService: auth)),
      );

      await tester.tap(find.text('Enviar link de recuperação'));
      await tester.pump();

      expect(find.text('Informe seu email.'), findsOneWidget);
      expect(auth.lastResetEmail, isNull);
    });
  });

  group('ForgotPasswordScreen — comportamento', () {
    testWidgets('chama sendPasswordResetEmail com o email correto',
        (tester) async {
      final auth = FakeAuthService();
      await tester.pumpWidget(
        MaterialApp(home: ForgotPasswordScreen(authService: auth)),
      );

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'teste@exemplo.com');
      await tester.tap(find.text('Enviar link de recuperação'));
      await tester.pumpAndSettle();

      expect(auth.lastResetEmail, 'teste@exemplo.com');
    });

    testWidgets('exibe snackbar de erro quando serviço falha', (tester) async {
      final auth = FakeAuthService()..shouldThrow = true;
      await tester.pumpWidget(
        MaterialApp(home: ForgotPasswordScreen(authService: auth)),
      );

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'teste@exemplo.com');
      await tester.tap(find.text('Enviar link de recuperação'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Falha ao enviar email:'), findsOneWidget);
    });
  });
}
