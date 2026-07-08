import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/establishment_service.dart';
import '../services/nearby_establishments_service.dart';
import '../services/queue_service.dart';
import 'home_screen.dart';
import 'my_establishments_screen.dart';

class MainShell extends StatefulWidget {
  final AuthService authService;
  final EstablishmentService establishmentService;
  final QueueService queueService;
  final NearbyEstablishmentsService? nearbyEstablishmentsService;
  final FirebaseMessaging messaging;
  final FirebaseFirestore firestore;

  MainShell({
    super.key,
    required this.authService,
    EstablishmentService? establishmentService,
    QueueService? queueService,
    this.nearbyEstablishmentsService,
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : establishmentService = establishmentService ?? EstablishmentService(),
        queueService = queueService ?? QueueService(),
        messaging = messaging ?? FirebaseMessaging.instance,
        firestore = firestore ?? FirebaseFirestore.instance;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  StreamSubscription<String>? _tokenRefreshSub;

  @override
  void initState() {
    super.initState();
    _syncFcmToken();
    _tokenRefreshSub =
        widget.messaging.onTokenRefresh.listen(_saveFcmToken);
  }

  @override
  void dispose() {
    _tokenRefreshSub?.cancel();
    super.dispose();
  }

  Future<void> _syncFcmToken() async {
    final token = await widget.messaging.getToken();
    if (token != null) await _saveFcmToken(token);
  }

  Future<void> _saveFcmToken(String token) async {
    final uid = widget.authService.currentUser?.uid;
    if (uid == null) return;
    await widget.firestore
        .collection('users')
        .doc(uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

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
            nearbyEstablishmentsService: widget.nearbyEstablishmentsService,
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
