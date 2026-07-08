import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'firebase_options.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/deep_link_handler.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessaging.instance.requestPermission();
  FlutterNativeSplash.remove();
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  final AuthService? authService;
  const MyApp({super.key, this.authService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final DeepLinkHandler _deepLinkHandler;
  StreamSubscription<Uri>? _sub;
  final _appLinks = AppLinks();

  // Evita duplicatas: app_links pode emitir o mesmo URI tanto em
  // getInitialLink() quanto no uriLinkStream quando o app abre a frio.
  String? _lastHandledUri;

  @override
  void initState() {
    super.initState();
    _deepLinkHandler = DeepLinkHandler(navigatorKey: navigatorKey);
    _handleInitialUri();
    _sub = _appLinks.uriLinkStream.listen(
      _dispatchUri,
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _dispatchUri(Uri uri) {
    final key = uri.toString();
    if (key == _lastHandledUri) return;
    _lastHandledUri = key;
    _deepLinkHandler.handleUri(uri);
    // Libera após 2 s para permitir que o mesmo link seja acionado novamente
    Future.delayed(const Duration(seconds: 2), () => _lastHandledUri = null);
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) _dispatchUri(uri);
    } catch (_) {}
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
      home: SplashScreen(next: AuthGate(authService: service)),
      routes: {
        RegisterScreen.routeName: (context) => RegisterScreen(authService: service),
        ForgotPasswordScreen.routeName: (context) =>
            ForgotPasswordScreen(authService: service),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  final AuthService authService;
  const AuthGate({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) return MainShell(authService: authService);
        return LoginScreen(authService: authService);
      },
    );
  }
}
