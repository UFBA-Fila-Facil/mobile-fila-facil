import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_fila_facil/models/establishment.dart';
import 'package:mobile_fila_facil/models/queue_model.dart';
import 'package:mobile_fila_facil/screens/my_establishments_screen.dart';
import 'package:mobile_fila_facil/services/auth_service.dart';
import 'package:mobile_fila_facil/services/establishment_service.dart';
import 'package:mobile_fila_facil/services/queue_service.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockAuthService extends Mock implements AuthService {}

class MockEstablishmentService extends Mock implements EstablishmentService {}

class MockQueueService extends Mock implements QueueService {}

class MockFirebaseUser extends Mock implements User {}

class FakeEstablishment extends Fake implements Establishment {}

class FakeQueueModel extends Fake implements QueueModel {}

// ── Fixtures ──────────────────────────────────────────────────────────────────

Establishment _makeEstablishment({
  String id = 'est-1',
  String name = 'Mercado',
  int capacity = 25,
  String serviceType = 'Caixas',
}) =>
    Establishment(
      id: id,
      name: name,
      cep: '01001000',
      address: 'Rua A, 1',
      capacity: capacity,
      serviceType: serviceType,
      adminId: 'admin-1',
      createdAt: DateTime.utc(2026, 1, 1),
    );

QueueModel _makeQueue({
  required String estId,
  required int qty,
  int waitTime = 5,
}) =>
    QueueModel(
      id: 'q-$estId',
      establishmentId: estId,
      quantityPeople: qty,
      averageWaitingTime: waitTime,
      serviceType: 'Caixas',
    );

Widget _buildScreen({
  required MockAuthService auth,
  required MockEstablishmentService est,
  required MockQueueService queue,
}) =>
    MaterialApp(
      home: MyEstablishmentsScreen(
        authService: auth,
        establishmentService: est,
        queueService: queue,
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(FakeEstablishment());
    registerFallbackValue(FakeQueueModel());
  });

  group('MyEstablishmentsScreen — estrutura básica', () {
    testWidgets('exibe título "Meus estabelecimentos"', (tester) async {
      final auth = MockAuthService();
      final est = MockEstablishmentService();
      final queue = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);
      when(() => est.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(_buildScreen(auth: auth, est: est, queue: queue));
      await tester.pump();

      expect(find.text('Meus estabelecimentos'), findsOneWidget);
    });

    testWidgets('exibe mensagem quando não há estabelecimentos', (tester) async {
      final auth = MockAuthService();
      final est = MockEstablishmentService();
      final queue = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);
      when(() => est.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(_buildScreen(auth: auth, est: est, queue: queue));
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhum estabelecimento cadastrado ainda.'),
        findsOneWidget,
      );
    });

    testWidgets('exibe botão "Cadastrar" quando usuário está autenticado',
        (tester) async {
      final auth = MockAuthService();
      final est = MockEstablishmentService();
      final queue = MockQueueService();
      final user = MockFirebaseUser();
      when(() => user.uid).thenReturn('user-123');
      when(() => auth.currentUser).thenReturn(user);
      when(() => est.watchUserEstablishments('user-123'))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(_buildScreen(auth: auth, est: est, queue: queue));
      await tester.pumpAndSettle();

      expect(find.text('Cadastrar'), findsOneWidget);
    });

    testWidgets('não exibe botão "Cadastrar" quando usuário não está autenticado',
        (tester) async {
      final auth = MockAuthService();
      final est = MockEstablishmentService();
      final queue = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);
      when(() => est.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(_buildScreen(auth: auth, est: est, queue: queue));
      await tester.pumpAndSettle();

      expect(find.text('Cadastrar'), findsNothing);
    });

    testWidgets('exibe nome do estabelecimento no card', (tester) async {
      final auth = MockAuthService();
      final est = MockEstablishmentService();
      final queue = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);

      final establishment = _makeEstablishment(id: 'est-1', name: 'Padaria Boa');
      when(() => est.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([establishment]));
      when(() => queue.watchQueueForEstablishment('est-1'))
          .thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(_buildScreen(auth: auth, est: est, queue: queue));
      await tester.pumpAndSettle();

      expect(find.text('Padaria Boa'), findsOneWidget);
    });
  });

  group('MyEstablishmentsScreen — status da fila nos cards', () {
    testWidgets('exibe status "Baixa" para menos de 5 pessoas', (tester) async {
      final auth = MockAuthService();
      final est = MockEstablishmentService();
      final queue = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);

      final establishment = _makeEstablishment(id: 'est-1');
      final queueData = _makeQueue(estId: 'est-1', qty: 3, waitTime: 5);
      when(() => est.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([establishment]));
      when(() => queue.watchQueueForEstablishment('est-1'))
          .thenAnswer((_) => Stream.value(queueData));

      await tester.pumpWidget(_buildScreen(auth: auth, est: est, queue: queue));
      await tester.pumpAndSettle();

      expect(find.text('Baixa'), findsOneWidget);
    });

    testWidgets('exibe status "Média" para 5–15 pessoas', (tester) async {
      final auth = MockAuthService();
      final est = MockEstablishmentService();
      final queue = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);

      final establishment = _makeEstablishment(id: 'est-2', name: 'Supermercado');
      final queueData = _makeQueue(estId: 'est-2', qty: 10, waitTime: 12);
      when(() => est.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([establishment]));
      when(() => queue.watchQueueForEstablishment('est-2'))
          .thenAnswer((_) => Stream.value(queueData));

      await tester.pumpWidget(_buildScreen(auth: auth, est: est, queue: queue));
      await tester.pumpAndSettle();

      expect(find.text('Média'), findsOneWidget);
    });

    testWidgets('exibe status "Alta" para mais de 15 pessoas', (tester) async {
      final auth = MockAuthService();
      final est = MockEstablishmentService();
      final queue = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);

      final establishment = _makeEstablishment(id: 'est-3', name: 'Shopping');
      final queueData = _makeQueue(estId: 'est-3', qty: 20, waitTime: 25);
      when(() => est.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([establishment]));
      when(() => queue.watchQueueForEstablishment('est-3'))
          .thenAnswer((_) => Stream.value(queueData));

      await tester.pumpWidget(_buildScreen(auth: auth, est: est, queue: queue));
      await tester.pumpAndSettle();

      expect(find.text('Alta'), findsOneWidget);
    });

    testWidgets('exibe "Sem dados" quando não há fila', (tester) async {
      final auth = MockAuthService();
      final est = MockEstablishmentService();
      final queue = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);

      final establishment = _makeEstablishment(id: 'est-1');
      when(() => est.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([establishment]));
      when(() => queue.watchQueueForEstablishment('est-1'))
          .thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(_buildScreen(auth: auth, est: est, queue: queue));
      await tester.pumpAndSettle();

      expect(find.text('Sem dados'), findsOneWidget);
    });
  });

  group('MyEstablishmentsScreen — botão "+1 cliente atendido"', () {
    testWidgets('exibe o botão quando há pessoas na fila', (tester) async {
      final auth = MockAuthService();
      final est = MockEstablishmentService();
      final queue = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);

      final establishment = _makeEstablishment(id: 'est-1', name: 'Lanchonete');
      final queueData = _makeQueue(estId: 'est-1', qty: 5);
      when(() => est.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([establishment]));
      when(() => queue.watchQueueForEstablishment('est-1'))
          .thenAnswer((_) => Stream.value(queueData));

      await tester.pumpWidget(_buildScreen(auth: auth, est: est, queue: queue));
      await tester.pumpAndSettle();

      expect(find.text('+1 cliente atendido'), findsOneWidget);
    });

    testWidgets('não exibe o botão quando a fila está vazia', (tester) async {
      final auth = MockAuthService();
      final est = MockEstablishmentService();
      final queue = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);

      final establishment = _makeEstablishment(id: 'est-1', name: 'Lanchonete');
      final queueData = _makeQueue(estId: 'est-1', qty: 0);
      when(() => est.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([establishment]));
      when(() => queue.watchQueueForEstablishment('est-1'))
          .thenAnswer((_) => Stream.value(queueData));

      await tester.pumpWidget(_buildScreen(auth: auth, est: est, queue: queue));
      await tester.pumpAndSettle();

      expect(find.text('+1 cliente atendido'), findsNothing);
    });

    testWidgets('não exibe o botão quando não há dados de fila', (tester) async {
      final auth = MockAuthService();
      final est = MockEstablishmentService();
      final queue = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);

      final establishment = _makeEstablishment(id: 'est-1');
      when(() => est.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([establishment]));
      when(() => queue.watchQueueForEstablishment('est-1'))
          .thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(_buildScreen(auth: auth, est: est, queue: queue));
      await tester.pumpAndSettle();

      expect(find.text('+1 cliente atendido'), findsNothing);
    });
  });
}
