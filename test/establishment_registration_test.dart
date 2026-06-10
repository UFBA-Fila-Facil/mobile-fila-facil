import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_fila_facil/models/establishment.dart';
import 'package:mobile_fila_facil/screens/establishment_registration_screen.dart';
import 'package:mobile_fila_facil/services/establishment_service.dart';
import 'package:mobile_fila_facil/services/queue_service.dart';

class MockEstablishmentService extends Mock implements EstablishmentService {}

class FakeEstablishment extends Fake implements Establishment {}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

class MockQueueService extends Mock implements QueueService {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeEstablishment());
  });

  testWidgets('Establishment registration screen renders all fields and button', (WidgetTester tester) async {
    final service = MockEstablishmentService();
    final queueService = MockQueueService();
    when(() => service.addEstablishment(any())).thenAnswer((_) async => 'created-id');

    await tester.pumpWidget(
      MaterialApp(
        home: EstablishmentRegistrationScreen(
          adminId: 'admin-1',
          establishmentService: service,
          queueService: queueService,
        ),
      ),
    );

    expect(find.text('Nome do estabelecimento'), findsOneWidget);
    expect(find.text('CEP'), findsOneWidget);
    expect(find.text('Endereço'), findsOneWidget);
    expect(find.text('Número e Complemento'), findsOneWidget);
    expect(find.text('Capacidade máxima da fila'), findsOneWidget);
    expect(find.text('Tipo de atendimento'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Salvar estabelecimento'), findsOneWidget);
  });

  testWidgets('Salvar estabelecimento calls service when form is valid', (WidgetTester tester) async {
    final service = MockEstablishmentService();
    final queueService = MockQueueService();
    when(() => service.addEstablishment(any())).thenAnswer((_) async => 'created-id');

    await tester.pumpWidget(
      MaterialApp(home: const Scaffold()),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(MaterialPageRoute(
      builder: (_) => EstablishmentRegistrationScreen(
        adminId: 'admin-1',
        establishmentService: service,
        queueService: queueService,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome do estabelecimento'), 'Mercado Fácil');
    await tester.enterText(find.widgetWithText(TextFormField, 'CEP'), '01310900');
    await tester.enterText(find.widgetWithText(TextFormField, 'Número e Complemento'), '100');
    await tester.enterText(find.widgetWithText(TextFormField, 'Capacidade máxima da fila'), '25');
    await tester.enterText(find.widgetWithText(TextFormField, 'Tipo de atendimento'), 'Caixas');

    final addressController = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Endereço')).controller!;
    addressController.text = 'Rua Central, 100';
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar estabelecimento'));
    await tester.pumpAndSettle();

    verify(() => service.addEstablishment(any())).called(1);
  });

  testWidgets('Validation prevents saving when capacity is invalid', (WidgetTester tester) async {
    final service = MockEstablishmentService();
    final queueService = MockQueueService();
    when(() => service.addEstablishment(any())).thenAnswer((_) async => 'created-id');

    await tester.pumpWidget(
      MaterialApp(home: EstablishmentRegistrationScreen(adminId: 'admin-1', establishmentService: service, queueService: queueService)),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome do estabelecimento'), 'Mercado Fácil');
    await tester.enterText(find.widgetWithText(TextFormField, 'CEP'), '01310900');
    await tester.enterText(find.widgetWithText(TextFormField, 'Número e Complemento'), '-5');
    await tester.enterText(find.widgetWithText(TextFormField, 'Capacidade máxima da fila'), '-5');
    await tester.enterText(find.widgetWithText(TextFormField, 'Tipo de atendimento'), 'Caixas');

    final addressController = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Endereço')).controller!;
    addressController.text = 'Rua Central, 100';
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar estabelecimento'));
    await tester.pump();

    expect(find.text('Informe um número válido maior que zero.'), findsOneWidget);
    verifyNever(() => service.addEstablishment(any()));
  });

  testWidgets('Existing establishment with location displays latitude and longitude', (WidgetTester tester) async {
    final service = MockEstablishmentService();
    final establishment = Establishment(
      id: 'id-1',
      name: 'Mercado Fácil',
      cep: '01001000',
      address: 'Rua Central, 100',
      capacity: 25,
      serviceType: 'Caixas',
      adminId: 'admin-1',
      createdAt: DateTime.now(),
      location: const GeoPoint(-23.550520, -46.633308),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EstablishmentRegistrationScreen(
          adminId: 'admin-1',
          establishmentService: service,
          establishment: establishment,
        ),
      ),
    );

    expect(find.textContaining('Latitude:'), findsOneWidget);
    expect(find.textContaining('Longitude:'), findsOneWidget);
  });

  test('Establishment model converts to map correctly', () {
    final createdAt = DateTime.utc(2026, 6, 4, 12, 0, 0);
    final establishment = Establishment(
      id: 'id-1',
      name: 'Mercado',
      cep: '01001000',
      address: 'Rua A, 123',
      capacity: 15,
      serviceType: 'Caixas',
      adminId: 'admin-1',
      createdAt: createdAt,
      location: const GeoPoint(-23.550520, -46.633308),
    );

    final map = establishment.toMap();

    expect(map['name'], 'Mercado');
    expect(map['address'], 'Rua A, 123');
    expect(map['capacity'], 15);
    expect(map['serviceType'], 'Caixas');
    expect(map['adminId'], 'admin-1');
    expect(map['createdAt'], isA<Timestamp>());
    expect(map['location'], isA<GeoPoint>());
    expect((map['location'] as GeoPoint).latitude, -23.550520);
    expect((map['location'] as GeoPoint).longitude, -46.633308);
  });

  test('Establishment model creates instance from Firestore document with location', () {
    final doc = MockDocumentSnapshot();
    when(() => doc.id).thenReturn('id-1');
    when(() => doc.data()).thenReturn({
      'name': 'Mercado',
      'cep': '01001000',
      'address': 'Rua A, 123',
      'capacity': 15,
      'serviceType': 'Caixas',
      'adminId': 'admin-1',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 6, 4, 12, 0, 0)),
      'location': const GeoPoint(-23.550520, -46.633308),
    });

    final establishment = Establishment.fromDocument(doc);

    expect(establishment.id, 'id-1');
    expect(establishment.name, 'Mercado');
    expect(establishment.address, 'Rua A, 123');
    expect(establishment.capacity, 15);
    expect(establishment.serviceType, 'Caixas');
    expect(establishment.adminId, 'admin-1');
    expect(establishment.location, isA<GeoPoint>());
    expect(establishment.location!.latitude, -23.550520);
    expect(establishment.location!.longitude, -46.633308);
  });
}
