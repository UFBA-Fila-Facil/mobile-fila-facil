import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_fila_facil/models/establishment.dart';
import 'package:mobile_fila_facil/models/queue_model.dart';
import 'package:mobile_fila_facil/screens/main_shell.dart';
import 'package:mobile_fila_facil/services/auth_service.dart';
import 'package:mobile_fila_facil/services/establishment_service.dart';
import 'package:mobile_fila_facil/services/nearby_establishments_service.dart';
import 'package:mobile_fila_facil/services/queue_service.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockAuthService extends Mock implements AuthService {}

class MockEstablishmentService extends Mock implements EstablishmentService {}

class MockQueueService extends Mock implements QueueService {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class FakeEstablishment extends Fake implements Establishment {}

class FakeQueueModel extends Fake implements QueueModel {}

class FakeNearbyEstablishmentsService extends Fake
    implements NearbyEstablishmentsService {
  @override
  Future<List<NearbyEstablishment>> getNearbyEstablishments() async => [];
}

// ── Helpers ───────────────────────────────────────────────────────────────────

void _stubServices(
  MockAuthService auth,
  MockEstablishmentService est,
  MockQueueService queue,
  MockFirebaseMessaging messaging,
) {
  when(() => auth.currentUser).thenReturn(null);
  when(() => queue.watchUserActiveQueue(any())).thenAnswer((_) => Stream.value(null));
  when(() => est.watchUserEstablishments(any())).thenAnswer((_) => Stream.value([]));
  when(() => messaging.getToken()).thenAnswer((_) async => null);
  when(() => messaging.onTokenRefresh).thenAnswer((_) => const Stream.empty());
}

Widget _buildShell({
  required MockAuthService auth,
  required MockEstablishmentService est,
  required MockQueueService queue,
  required MockFirebaseMessaging messaging,
  required MockFirebaseFirestore firestore,
}) =>
    MaterialApp(
      home: MainShell(
        authService: auth,
        establishmentService: est,
        queueService: queue,
        nearbyEstablishmentsService: FakeNearbyEstablishmentsService(),
        messaging: messaging,
        firestore: firestore,
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(FakeEstablishment());
    registerFallbackValue(FakeQueueModel());
  });

  group('MainShell — navegação', () {
    testWidgets('exibe barra de navegação com abas corretas', (tester) async {
      final auth = MockAuthService();
      final est = MockEstablishmentService();
      final queue = MockQueueService();
      final messaging = MockFirebaseMessaging();
      final firestore = MockFirebaseFirestore();
      _stubServices(auth, est, queue, messaging);

      await tester.pumpWidget(_buildShell(
        auth: auth,
        est: est,
        queue: queue,
        messaging: messaging,
        firestore: firestore,
      ));
      await tester.pump();

      expect(find.text('Início'), findsOneWidget);
      expect(find.text('Meus estabelecimentos'), findsWidgets);
    });

    testWidgets('exibe HomeScreen como tela inicial (aba Início)', (tester) async {
      final auth = MockAuthService();
      final est = MockEstablishmentService();
      final queue = MockQueueService();
      final messaging = MockFirebaseMessaging();
      final firestore = MockFirebaseFirestore();
      _stubServices(auth, est, queue, messaging);

      await tester.pumpWidget(_buildShell(
        auth: auth,
        est: est,
        queue: queue,
        messaging: messaging,
        firestore: firestore,
      ));
      await tester.pump();

      expect(
        find.text('Busque um estabelecimento para entrar na fila.'),
        findsOneWidget,
      );
    });

    testWidgets('navega para MyEstablishmentsScreen ao tocar na segunda aba',
        (tester) async {
      final auth = MockAuthService();
      final est = MockEstablishmentService();
      final queue = MockQueueService();
      final messaging = MockFirebaseMessaging();
      final firestore = MockFirebaseFirestore();
      _stubServices(auth, est, queue, messaging);

      await tester.pumpWidget(_buildShell(
        auth: auth,
        est: est,
        queue: queue,
        messaging: messaging,
        firestore: firestore,
      ));
      await tester.pump();

      await tester.tap(find.text('Meus estabelecimentos').last);
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhum estabelecimento cadastrado ainda.'),
        findsOneWidget,
      );
    });
  });
}
