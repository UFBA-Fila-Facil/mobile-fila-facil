import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // Import the generated file
import 'package:uni_links/uni_links.dart';
import 'dart:async';

import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/auth_service.dart';
import 'services/app_actions_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  final AuthService? authService;
  const MyApp({super.key, this.authService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<Uri?>? _sub;
  final AppActionsHandler _handler = AppActionsHandler();

  @override
  void initState() {
    super.initState();
    // Handle initial uri
    _handleInitialUri();
    // Listen for incoming links while app is running
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) _processUri(uri);
    }, onError: (err) {
      // ignore
    });
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = await getInitialUri();
      if (uri != null) _processUri(uri);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _processUri(Uri uri) async {
    final context = navigatorKey.currentState?.context;
    if (context == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await _showDialog(
        context,
        'Autenticação necessária',
        'Você precisa estar autenticado no app para alterar o estado da fila.',
      );
      return;
    }

    final params = uri.queryParameters;
    final establishmentName = params['establishmentName'] ?? params['name'];
    final quantity = _parseInt(params['quantity'] ?? params['quantityPeople']);
    final wait = _parseInt(params['wait'] ?? params['averageWaitTime']);

    if ((quantity == null && wait == null) || establishmentName == null || establishmentName.isEmpty) {
      await _showDialog(
        context,
        'Parâmetros inválidos',
        'O deeplink deve informar o nome do estabelecimento e pelo menos a quantidade de pessoas ou o tempo médio de espera.',
      );
      return;
    }

    final establishment = await _handler.findUserEstablishment(
      userId: user.uid,
      establishmentName: establishmentName,
    );

    if (establishment == null) {
      await _showDialog(
        context,
        'Estabelecimento não encontrado',
        'Não foi encontrado nenhum estabelecimento com o nome "$establishmentName" entre os seus estabelecimentos.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar alteração de fila'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estabelecimento: ${establishment.name}'),
              if (quantity != null) Text('Quantidade de pessoas: $quantity'),
              if (wait != null) Text('Tempo m�dio de espera: $wait minutos'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final result = await _handler.updateQueue(
        establishmentId: establishment.id,
        quantityPeople: quantity,
        averageWaitTime: wait,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    } catch (e) {
      await _showDialog(
        context,
        'Erro ao alterar fila',
        e.toString(),
      );
    }
  }

  int? _parseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  Future<void> _showDialog(BuildContext context, String title, String message) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.authService ?? FirebaseAuthService();

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Fila Fácil',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AuthGate(authService: service),
      routes: {
        RegisterScreen.routeName: (context) => RegisterScreen(authService: service),
        ForgotPasswordScreen.routeName: (context) => ForgotPasswordScreen(authService: service),
      },
    );
  }
}

// Global navigator key used to show SnackBar from URI handler
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AuthGate extends StatelessWidget {
  final AuthService authService;
  const AuthGate({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return HomeScreen(authService: authService);
        }

        return LoginScreen(authService: authService);
      },
    );
  }
}
