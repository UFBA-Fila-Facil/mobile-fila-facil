import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_fila_facil/models/establishment.dart';
import 'package:mobile_fila_facil/models/queue_model.dart';
import 'package:mobile_fila_facil/screens/home_screen.dart';
import 'package:mobile_fila_facil/services/auth_service.dart';
import 'package:mobile_fila_facil/services/establishment_service.dart';
import 'package:mobile_fila_facil/services/queue_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockEstablishmentService extends Mock implements EstablishmentService {}

class MockQueueService extends Mock implements QueueService {}

class FakeEstablishment extends Fake implements Establishment {}

class FakeQueueModel extends Fake implements QueueModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeEstablishment());
    registerFallbackValue(FakeQueueModel());
  });

  testWidgets('Queue status displays green light for less than 5 people', (WidgetTester tester) async {
    final authService = MockAuthService();
    final establishmentService = MockEstablishmentService();
    final queueService = MockQueueService();

    final establishment = Establishment(
      id: 'est-1',
      name: 'Mercado',
      cep: '01001000',
      address: 'Rua A',
      capacity: 25,
      serviceType: 'Caixas',
      adminId: 'admin-1',
      createdAt: DateTime.now(),
    );

    final queue = QueueModel(
      id: 'queue-1',
      establishmentId: 'est-1',
      quantityPeople: 3,
      averageWaitingTime: 5,
      serviceType: 'Caixas',
    );

    when(() => authService.currentUser).thenReturn(null);
    when(() => establishmentService.watchUserEstablishments(any())).thenAnswer((_) => Stream.value([establishment]));
    when(() => queueService.watchQueueForEstablishment('est-1')).thenAnswer((_) => Stream.value(queue));

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authService: authService,
          establishmentService: establishmentService,
          queueService: queueService,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Baixa'), findsOneWidget);
    expect(find.textContaining('Pessoas na fila'), findsOneWidget);
    expect(find.textContaining('Tempo esperado'), findsOneWidget);
  });

  testWidgets('Queue status displays yellow light for 5-15 people', (WidgetTester tester) async {
    final authService = MockAuthService();
    final establishmentService = MockEstablishmentService();
    final queueService = MockQueueService();

    final establishment = Establishment(
      id: 'est-2',
      name: 'Supermercado',
      cep: '01001001',
      address: 'Rua B',
      capacity: 50,
      serviceType: 'Caixas',
      adminId: 'admin-1',
      createdAt: DateTime.now(),
    );

    final queue = QueueModel(
      id: 'queue-2',
      establishmentId: 'est-2',
      quantityPeople: 10,
      averageWaitingTime: 12,
      serviceType: 'Caixas',
    );

    when(() => authService.currentUser).thenReturn(null);
    when(() => establishmentService.watchUserEstablishments(any())).thenAnswer((_) => Stream.value([establishment]));
    when(() => queueService.watchQueueForEstablishment('est-2')).thenAnswer((_) => Stream.value(queue));

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authService: authService,
          establishmentService: establishmentService,
          queueService: queueService,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Pessoas na fila'), findsOneWidget);
    expect(find.textContaining('10'), findsOneWidget);
    expect(find.textContaining('12 min'), findsOneWidget);
  });

  testWidgets('Queue status displays red light for more than 15 people', (WidgetTester tester) async {
    final authService = MockAuthService();
    final establishmentService = MockEstablishmentService();
    final queueService = MockQueueService();

    final establishment = Establishment(
      id: 'est-3',
      name: 'Shopping',
      cep: '01001002',
      address: 'Rua C',
      capacity: 100,
      serviceType: 'Atendimento',
      adminId: 'admin-1',
      createdAt: DateTime.now(),
    );

    final queue = QueueModel(
      id: 'queue-3',
      establishmentId: 'est-3',
      quantityPeople: 25,
      averageWaitingTime: 20,
      serviceType: 'Atendimento',
    );

    when(() => authService.currentUser).thenReturn(null);
    when(() => establishmentService.watchUserEstablishments(any())).thenAnswer((_) => Stream.value([establishment]));
    when(() => queueService.watchQueueForEstablishment('est-3')).thenAnswer((_) => Stream.value(queue));

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authService: authService,
          establishmentService: establishmentService,
          queueService: queueService,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Alta'), findsOneWidget);
    expect(find.textContaining('25'), findsOneWidget);
    expect(find.textContaining('20 min'), findsOneWidget);
  });

  test('Queue model creates instance from Firestore document', () {
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
}

class MockFirestoreDoc extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
