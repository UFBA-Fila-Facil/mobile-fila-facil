import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/establishment_service.dart';
import '../services/queue_service.dart';
import 'home_screen.dart';
import 'my_establishments_screen.dart';

class MainShell extends StatefulWidget {
  final AuthService authService;
  final EstablishmentService establishmentService;
  final QueueService queueService;

  MainShell({
    super.key,
    required this.authService,
    EstablishmentService? establishmentService,
    QueueService? queueService,
  })  : establishmentService = establishmentService ?? EstablishmentService(),
        queueService = queueService ?? QueueService();

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            authService: widget.authService,
            establishmentService: widget.establishmentService,
            queueService: widget.queueService,
          ),
          MyEstablishmentsScreen(
            authService: widget.authService,
            establishmentService: widget.establishmentService,
            queueService: widget.queueService,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF0CA79B),
        unselectedItemColor: Colors.black45,
        backgroundColor: Colors.white,
        elevation: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Meus estabelecimentos',
          ),
        ],
      ),
    );
  }
}
