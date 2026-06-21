import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_fila_facil/models/establishment.dart';
import 'package:mobile_fila_facil/models/queue_model.dart';
import 'package:mobile_fila_facil/models/user_queue_entry.dart';
import 'package:mobile_fila_facil/screens/home_screen.dart';
import 'package:mobile_fila_facil/services/auth_service.dart';
import 'package:mobile_fila_facil/services/establishment_service.dart';
import 'package:mobile_fila_facil/services/queue_service.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockAuthService extends Mock implements AuthService {}

class MockEstablishmentService extends Mock implements EstablishmentService {}

class MockQueueService extends Mock implements QueueService {}

class FakeEstablishment extends Fake implements Establishment {}

class FakeQueueModel extends Fake implements QueueModel {}

class MockFirestoreDoc extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

// ── Fixtures ──────────────────────────────────────────────────────────────────

Establishment _makeEstablishment({
  String id = 'est-1',
  String name = 'Mercado',
  int capacity = 25,
}) =>
    Establishment(
      id: id,
      name: name,
      cep: '01001000',
      address: 'Rua A, 1',
      capacity: capacity,
      serviceType: 'Caixas',
      adminId: 'admin-1',
      createdAt: DateTime.utc(2026, 1, 1),
    );

QueueModel _makeQueue({
  required String estId,
  required int qty,
  required int waitTime,
}) =>
    QueueModel(
      id: 'q-$estId',
      establishmentId: estId,
      quantityPeople: qty,
      averageWaitingTime: waitTime,
      serviceType: 'Caixas',
    );

UserQueueEntry _makeEntry({
  String id = 'entry-1',
  String estId = 'est-1',
  String queueId = 'q-est-1',
  int position = 3,
}) =>
    UserQueueEntry(
      id: id,
      userId: 'user-1',
      establishmentId: estId,
      queueId: queueId,
      joinedAt: DateTime.utc(2026, 1, 1),
      active: true,
      position: position,
    );

/// Stubs mínimos para renderizar HomeScreen sem fila ativa e sem estabelecimentos.
void _stubIdle(
  MockAuthService auth,
  MockEstablishmentService est,
  MockQueueService queue,
) {
  when(() => auth.currentUser).thenReturn(null);
  when(() => queue.watchUserActiveQueue(any())).thenAnswer((_) => Stream.value(null));
  when(() => est.watchUserEstablishments(any())).thenAnswer((_) => Stream.value([]));
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(FakeEstablishment());
    registerFallbackValue(FakeQueueModel());
  });

  // ── Card de busca (sem fila ativa) ──────────────────────────────────────────

  group('HomeScreen — card de busca (usuário sem fila)', () {
    testWidgets('exibe campo de busca e mensagem inicial', (tester) async {
      final auth = MockAuthService();
      final est = MockEstablishmentService();
      final queue = MockQueueService();
      _stubIdle(auth, est, queue);

      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          authService: auth,
          establishmentService: est,
          queueService: queue,
        ),
      ));
      await tester.pump();

      expect(
        find.text('Busque um estabelecimento para entrar na fila.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('exibe resultados da busca após digitar', (tester) async {
      final auth = MockAuthService();
      final estService = MockEstablishmentService();
      final queueService = MockQueueService();
      _stubIdle(auth, estService, queueService);

      final result = _makeEstablishment(id: 'est-search', name: 'Padaria Central');
      when(() => estService.searchEstablishments(any()))
          .thenAnswer((_) async => [result]);
      when(() => queueService.watchQueueForEstablishment('est-search'))
          .thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          authService: auth,
          establishmentService: estService,
          queueService: queueService,
        ),
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Padaria');
      await tester.pump(const Duration(milliseconds: 450)); // aguarda debounce
      await tester.pumpAndSettle();

      expect(find.text('Padaria Central'), findsOneWidget);
    });

    testWidgets('exibe estado vazio quando busca não encontra nada', (tester) async {
      final auth = MockAuthService();
      final estService = MockEstablishmentService();
      final queueService = MockQueueService();
      _stubIdle(auth, estService, queueService);

      when(() => estService.searchEstablishments(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          authService: auth,
          establishmentService: estService,
          queueService: queueService,
        ),
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum estabelecimento encontrado.'), findsOneWidget);
    });
  });

  // ── Card de fila ativa ──────────────────────────────────────────────────────

  group('HomeScreen — card de fila ativa (usuário na fila)', () {
    testWidgets('exibe nome, status e tempo de espera quando está na fila',
        (tester) async {
      final auth = MockAuthService();
      final estService = MockEstablishmentService();
      final queueService = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);
      when(() => estService.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([]));

      final entry = _makeEntry(estId: 'est-1', position: 3);
      final establishment = _makeEstablishment(id: 'est-1', name: 'Farmácia Popular');
      final queue = _makeQueue(estId: 'est-1', qty: 8, waitTime: 10);

      when(() => queueService.watchUserActiveQueue(any()))
          .thenAnswer((_) => Stream.value(entry));
      when(() => estService.watchEstablishment('est-1'))
          .thenAnswer((_) => Stream.value(establishment));
      when(() => queueService.watchQueueForEstablishment('est-1'))
          .thenAnswer((_) => Stream.value(queue));

      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          authService: auth,
          establishmentService: estService,
          queueService: queueService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Você está na fila'), findsOneWidget);
      expect(find.text('Farmácia Popular'), findsOneWidget);
      expect(find.text('Média'), findsOneWidget); // 8 pessoas → Média
      expect(find.text('10 min'), findsOneWidget);
      expect(find.text('Sair da fila'), findsOneWidget);
    });

    testWidgets('exibe badge de posição do usuário na fila', (tester) async {
      final auth = MockAuthService();
      final estService = MockEstablishmentService();
      final queueService = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);
      when(() => estService.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([]));

      final entry = _makeEntry(estId: 'est-1', position: 2);
      when(() => queueService.watchUserActiveQueue(any()))
          .thenAnswer((_) => Stream.value(entry));
      when(() => estService.watchEstablishment('est-1'))
          .thenAnswer((_) => Stream.value(null));
      when(() => queueService.watchQueueForEstablishment('est-1'))
          .thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          authService: auth,
          establishmentService: estService,
          queueService: queueService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Posição'), findsOneWidget);
      expect(find.text('2º'), findsOneWidget);
    });

    testWidgets('exibe botão "Fui atendido" quando usuário está na fila',
        (tester) async {
      final auth = MockAuthService();
      final estService = MockEstablishmentService();
      final queueService = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);
      when(() => estService.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([]));

      final entry = _makeEntry();
      when(() => queueService.watchUserActiveQueue(any()))
          .thenAnswer((_) => Stream.value(entry));
      when(() => estService.watchEstablishment(any()))
          .thenAnswer((_) => Stream.value(null));
      when(() => queueService.watchQueueForEstablishment(any()))
          .thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          authService: auth,
          establishmentService: estService,
          queueService: queueService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Fui atendido'), findsOneWidget);
    });

    testWidgets('não exibe campo de busca quando usuário está na fila', (tester) async {
      final auth = MockAuthService();
      final estService = MockEstablishmentService();
      final queueService = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);
      when(() => estService.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([]));

      final entry = _makeEntry();
      when(() => queueService.watchUserActiveQueue(any()))
          .thenAnswer((_) => Stream.value(entry));
      when(() => estService.watchEstablishment(any()))
          .thenAnswer((_) => Stream.value(null));
      when(() => queueService.watchQueueForEstablishment(any()))
          .thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          authService: auth,
          establishmentService: estService,
          queueService: queueService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });
  });

  // ── Status na lista de estabelecimentos ────────────────────────────────────

  group('HomeScreen — status da fila nos cards de estabelecimento', () {
    testWidgets('exibe status Baixa para menos de 5 pessoas', (tester) async {
      final auth = MockAuthService();
      final estService = MockEstablishmentService();
      final queueService = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);
      when(() => queueService.watchUserActiveQueue(any()))
          .thenAnswer((_) => Stream.value(null));

      final est = _makeEstablishment(id: 'est-1');
      final queue = _makeQueue(estId: 'est-1', qty: 3, waitTime: 5);
      when(() => estService.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([est]));
      when(() => queueService.watchQueueForEstablishment('est-1'))
          .thenAnswer((_) => Stream.value(queue));

      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          authService: auth,
          establishmentService: estService,
          queueService: queueService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Baixa'), findsOneWidget);
      expect(find.textContaining('Pessoas na fila'), findsOneWidget);
      expect(find.textContaining('Tempo esperado'), findsOneWidget);
    });

    testWidgets('exibe dados da fila para 5–15 pessoas', (tester) async {
      final auth = MockAuthService();
      final estService = MockEstablishmentService();
      final queueService = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);
      when(() => queueService.watchUserActiveQueue(any()))
          .thenAnswer((_) => Stream.value(null));

      final est = _makeEstablishment(id: 'est-2', name: 'Supermercado');
      final queue = _makeQueue(estId: 'est-2', qty: 10, waitTime: 12);
      when(() => estService.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([est]));
      when(() => queueService.watchQueueForEstablishment('est-2'))
          .thenAnswer((_) => Stream.value(queue));

      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          authService: auth,
          establishmentService: estService,
          queueService: queueService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pessoas na fila'), findsOneWidget);
      expect(find.textContaining('10'), findsOneWidget);
      expect(find.textContaining('12 min'), findsOneWidget);
    });

    testWidgets('exibe status Alta para mais de 15 pessoas', (tester) async {
      final auth = MockAuthService();
      final estService = MockEstablishmentService();
      final queueService = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);
      when(() => queueService.watchUserActiveQueue(any()))
          .thenAnswer((_) => Stream.value(null));

      final est = _makeEstablishment(id: 'est-3', name: 'Shopping');
      final queue = _makeQueue(estId: 'est-3', qty: 25, waitTime: 20);
      when(() => estService.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([est]));
      when(() => queueService.watchQueueForEstablishment('est-3'))
          .thenAnswer((_) => Stream.value(queue));

      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          authService: auth,
          establishmentService: estService,
          queueService: queueService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Alta'), findsWidgets);
      expect(find.textContaining('25'), findsWidgets);
      expect(find.textContaining('20 min'), findsOneWidget);
    });
  });

  // ── Botão "+1 cliente atendido" no card do estabelecimento ────────────────

  group('HomeScreen — botão "+1 cliente atendido" no card do estabelecimento', () {
    testWidgets('exibe o botão quando há pessoas na fila', (tester) async {
      final auth = MockAuthService();
      final estService = MockEstablishmentService();
      final queueService = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);
      when(() => queueService.watchUserActiveQueue(any()))
          .thenAnswer((_) => Stream.value(null));

      final est = _makeEstablishment(id: 'est-1', name: 'Lanchonete');
      final queue = _makeQueue(estId: 'est-1', qty: 5, waitTime: 8);
      when(() => estService.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([est]));
      when(() => queueService.watchQueueForEstablishment('est-1'))
          .thenAnswer((_) => Stream.value(queue));

      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          authService: auth,
          establishmentService: estService,
          queueService: queueService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('+1 cliente atendido'), findsOneWidget);
    });

    testWidgets('não exibe o botão quando a fila está vazia', (tester) async {
      final auth = MockAuthService();
      final estService = MockEstablishmentService();
      final queueService = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);
      when(() => queueService.watchUserActiveQueue(any()))
          .thenAnswer((_) => Stream.value(null));

      final est = _makeEstablishment(id: 'est-1', name: 'Lanchonete');
      final queue = _makeQueue(estId: 'est-1', qty: 0, waitTime: 0);
      when(() => estService.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([est]));
      when(() => queueService.watchQueueForEstablishment('est-1'))
          .thenAnswer((_) => Stream.value(queue));

      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          authService: auth,
          establishmentService: estService,
          queueService: queueService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('+1 cliente atendido'), findsNothing);
    });

    testWidgets('não exibe o botão quando não há dados de fila', (tester) async {
      final auth = MockAuthService();
      final estService = MockEstablishmentService();
      final queueService = MockQueueService();
      when(() => auth.currentUser).thenReturn(null);
      when(() => queueService.watchUserActiveQueue(any()))
          .thenAnswer((_) => Stream.value(null));

      final est = _makeEstablishment(id: 'est-1');
      when(() => estService.watchUserEstablishments(any()))
          .thenAnswer((_) => Stream.value([est]));
      when(() => queueService.watchQueueForEstablishment('est-1'))
          .thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          authService: auth,
          establishmentService: estService,
          queueService: queueService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('+1 cliente atendido'), findsNothing);
    });
  });

  // ── Modelo QueueModel ──────────────────────────────────────────────────────

  group('QueueModel.fromDocument', () {
    test('mapeia todos os campos corretamente', () {
      final doc = MockFirestoreDoc();
      when(() => doc.id).thenReturn('queue-1');
      when(() => doc.data()).thenReturn({
        'establishmentId': 'est-1',
        'quantityPeople': 10,
        'averageWaitingTime': 15,
        'serviceType': 'Caixas',
        'active': true,
      });

      final queue = QueueModel.fromDocument(doc);

      expect(queue.id, 'queue-1');
      expect(queue.establishmentId, 'est-1');
      expect(queue.quantityPeople, 10);
      expect(queue.averageWaitingTime, 15);
      expect(queue.serviceType, 'Caixas');
      expect(queue.active, true);
    });

    test('usa defaults quando campos opcionais estão ausentes', () {
      final doc = MockFirestoreDoc();
      when(() => doc.id).thenReturn('queue-2');
      when(() => doc.data()).thenReturn({'establishmentId': 'est-1'});

      final queue = QueueModel.fromDocument(doc);

      expect(queue.quantityPeople, 0);
      expect(queue.averageWaitingTime, 0);
      expect(queue.serviceType, '');
      expect(queue.active, true);
    });
  });

  // ── Modelo UserQueueEntry ──────────────────────────────────────────────────

  group('UserQueueEntry.fromDocument', () {
    test('mapeia todos os campos corretamente', () {
      final doc = MockFirestoreDoc();
      final now = DateTime.utc(2026, 6, 10, 12, 0, 0);
      when(() => doc.id).thenReturn('entry-1');
      when(() => doc.data()).thenReturn({
        'userId': 'user-1',
        'establishmentId': 'est-1',
        'queueId': 'q-est-1',
        'joinedAt': Timestamp.fromDate(now),
        'active': true,
        'position': 4,
      });

      final entry = UserQueueEntry.fromDocument(doc);

      expect(entry.id, 'entry-1');
      expect(entry.userId, 'user-1');
      expect(entry.establishmentId, 'est-1');
      expect(entry.queueId, 'q-est-1');
      expect(entry.joinedAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(entry.active, true);
      expect(entry.position, 4);
    });

    test('queueId e position usam defaults quando ausentes', () {
      final doc = MockFirestoreDoc();
      when(() => doc.id).thenReturn('entry-2');
      when(() => doc.data()).thenReturn({
        'userId': 'user-1',
        'establishmentId': 'est-1',
        'joinedAt': Timestamp.fromDate(DateTime.now()),
      });

      final entry = UserQueueEntry.fromDocument(doc);

      expect(entry.queueId, '');
      expect(entry.position, 0);
      expect(entry.active, true);
    });

    test('toMap serializa todos os campos corretamente', () {
      final now = DateTime.utc(2026, 6, 10, 12, 0, 0);
      final entry = UserQueueEntry(
        id: 'entry-1',
        userId: 'user-1',
        establishmentId: 'est-1',
        queueId: 'q-est-1',
        joinedAt: now,
        active: false,
        position: 2,
      );

      final map = entry.toMap();

      expect(map['userId'], 'user-1');
      expect(map['establishmentId'], 'est-1');
      expect(map['queueId'], 'q-est-1');
      expect(map['active'], false);
      expect(map['position'], 2);
      expect(map['joinedAt'], isA<Timestamp>());
      expect(
        (map['joinedAt'] as Timestamp).toDate().millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
    });
  });
}
