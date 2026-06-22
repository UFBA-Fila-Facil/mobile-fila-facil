import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_fila_facil/models/establishment.dart';
import 'package:mobile_fila_facil/models/queue_model.dart';
import 'package:mobile_fila_facil/screens/queue_registration_screen.dart';
import 'package:mobile_fila_facil/services/queue_service.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockQueueService extends Mock implements QueueService {}

class FakeQueueModel extends Fake implements QueueModel {}

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _establishment = Establishment(
  id: 'est-1',
  name: 'Farmácia',
  cep: '01001000',
  address: 'Rua A, 1',
  capacity: 10,
  serviceType: 'Balcão',
  adminId: 'admin-1',
  createdAt: DateTime.utc(2026, 1, 1),
);

final _existingQueue = QueueModel(
  id: 'q-1',
  establishmentId: 'est-1',
  quantityPeople: 7,
  averageWaitingTime: 12,
  serviceType: 'Caixa',
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(FakeQueueModel());
  });

  group('QueueRegistrationScreen — modo criação', () {
    testWidgets('exibe nome e endereço do estabelecimento', (tester) async {
      final queue = MockQueueService();
      await tester.pumpWidget(MaterialApp(
        home: QueueRegistrationScreen(
          establishment: _establishment,
          queueService: queue,
        ),
      ));

      expect(find.text('Farmácia'), findsOneWidget);
      expect(find.text('Rua A, 1'), findsOneWidget);
    });

    testWidgets('exibe título "Registrar fila" quando não há fila existente',
        (tester) async {
      final queue = MockQueueService();
      await tester.pumpWidget(MaterialApp(
        home: QueueRegistrationScreen(
          establishment: _establishment,
          queueService: queue,
        ),
      ));

      expect(find.text('Registrar fila'), findsOneWidget);
      expect(find.text('Salvar fila'), findsOneWidget);
    });

    testWidgets('exibe campos de formulário vazios', (tester) async {
      final queue = MockQueueService();
      await tester.pumpWidget(MaterialApp(
        home: QueueRegistrationScreen(
          establishment: _establishment,
          queueService: queue,
        ),
      ));

      expect(
        find.widgetWithText(TextFormField, 'Quantidade de pessoas na fila'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Tempo médio de espera (min)'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Tipo de atendimento'),
        findsOneWidget,
      );
    });

    testWidgets('chama addQueue ao salvar formulário válido', (tester) async {
      final queue = MockQueueService();
      when(() => queue.addQueue(any())).thenAnswer((_) async => 'new-id');

      await tester.pumpWidget(MaterialApp(
        home: QueueRegistrationScreen(
          establishment: _establishment,
          queueService: queue,
        ),
      ));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantidade de pessoas na fila'),
        '5',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tempo médio de espera (min)'),
        '10',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tipo de atendimento'),
        'Caixas',
      );
      await tester.tap(find.text('Salvar fila'));
      await tester.pumpAndSettle();

      verify(() => queue.addQueue(any())).called(1);
    });
  });

  group('QueueRegistrationScreen — modo edição', () {
    testWidgets('exibe título "Editar fila" com fila existente', (tester) async {
      final queue = MockQueueService();
      await tester.pumpWidget(MaterialApp(
        home: QueueRegistrationScreen(
          establishment: _establishment,
          queueService: queue,
          queue: _existingQueue,
        ),
      ));

      expect(find.text('Editar fila'), findsOneWidget);
      expect(find.text('Salvar alterações'), findsOneWidget);
    });

    testWidgets('pré-preenche campos com dados da fila existente', (tester) async {
      final queue = MockQueueService();
      await tester.pumpWidget(MaterialApp(
        home: QueueRegistrationScreen(
          establishment: _establishment,
          queueService: queue,
          queue: _existingQueue,
        ),
      ));

      expect(find.text('7'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Caixa'), findsOneWidget);
    });

    testWidgets('chama updateQueue ao salvar fila existente', (tester) async {
      final queue = MockQueueService();
      when(() => queue.updateQueue(any())).thenAnswer((_) async {});

      await tester.pumpWidget(MaterialApp(
        home: QueueRegistrationScreen(
          establishment: _establishment,
          queueService: queue,
          queue: _existingQueue,
        ),
      ));

      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();

      verify(() => queue.updateQueue(any())).called(1);
    });
  });

  group('QueueRegistrationScreen — validação', () {
    testWidgets('rejeita quantidade vazia', (tester) async {
      final queue = MockQueueService();
      await tester.pumpWidget(MaterialApp(
        home: QueueRegistrationScreen(
          establishment: _establishment,
          queueService: queue,
        ),
      ));

      await tester.tap(find.text('Salvar fila'));
      await tester.pump();

      expect(find.text('Informe a quantidade de pessoas.'), findsOneWidget);
      verifyNever(() => queue.addQueue(any()));
    });

    testWidgets('rejeita quantidade negativa', (tester) async {
      final queue = MockQueueService();
      await tester.pumpWidget(MaterialApp(
        home: QueueRegistrationScreen(
          establishment: _establishment,
          queueService: queue,
        ),
      ));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantidade de pessoas na fila'),
        '-1',
      );
      await tester.tap(find.text('Salvar fila'));
      await tester.pump();

      expect(find.text('Informe um número válido.'), findsOneWidget);
      verifyNever(() => queue.addQueue(any()));
    });

    testWidgets('rejeita tempo médio vazio', (tester) async {
      final queue = MockQueueService();
      await tester.pumpWidget(MaterialApp(
        home: QueueRegistrationScreen(
          establishment: _establishment,
          queueService: queue,
        ),
      ));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantidade de pessoas na fila'),
        '5',
      );
      await tester.tap(find.text('Salvar fila'));
      await tester.pump();

      expect(find.text('Informe o tempo médio de espera.'), findsOneWidget);
      verifyNever(() => queue.addQueue(any()));
    });
  });
}
