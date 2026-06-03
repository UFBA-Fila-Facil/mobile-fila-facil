import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // Import the generated file

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService? authService;
  const MyApp({super.key, this.authService});

  @override
  Widget build(BuildContext context) {
    final service = authService ?? FirebaseAuthService();

    return MaterialApp(
      title: 'Fila Fácil',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AuthGate(authService: service),
      routes: {
        RegisterScreen.routeName: (context) => RegisterScreen(authService: service),
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
