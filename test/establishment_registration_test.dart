import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_fila_facil/models/establishment.dart';
import 'package:mobile_fila_facil/screens/establishment_registration_screen.dart';
import 'package:mobile_fila_facil/services/establishment_service.dart';

class MockEstablishmentService extends Mock implements EstablishmentService {}

class FakeEstablishment extends Fake implements Establishment {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeEstablishment());
  });

  testWidgets('Establishment registration screen renders all fields and button', (WidgetTester tester) async {
    final service = MockEstablishmentService();
    when(() => service.addEstablishment(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: EstablishmentRegistrationScreen(
          adminId: 'admin-1',
          establishmentService: service,
        ),
      ),
    );

    expect(find.text('Nome do estabelecimento'), findsOneWidget);
    expect(find.text('Endereço'), findsOneWidget);
    expect(find.text('Capacidade máxima da fila'), findsOneWidget);
    expect(find.text('Tipo de atendimento'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Salvar estabelecimento'), findsOneWidget);
  });

  testWidgets('Salvar estabelecimento calls service when form is valid', (WidgetTester tester) async {
    final service = MockEstablishmentService();
    when(() => service.addEstablishment(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(home: const Scaffold()),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(MaterialPageRoute(
      builder: (_) => EstablishmentRegistrationScreen(
        adminId: 'admin-1',
        establishmentService: service,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Mercado Fácil');
    await tester.enterText(find.byType(TextFormField).at(1), 'Rua Central, 100');
    await tester.enterText(find.byType(TextFormField).at(2), '25');
    await tester.enterText(find.byType(TextFormField).at(3), 'Caixas');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar estabelecimento'));
    await tester.pumpAndSettle();

    verify(() => service.addEstablishment(any())).called(1);
  });

  testWidgets('Validation prevents saving when capacity is invalid', (WidgetTester tester) async {
    final service = MockEstablishmentService();
    when(() => service.addEstablishment(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(home: EstablishmentRegistrationScreen(adminId: 'admin-1', establishmentService: service)),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Mercado Fácil');
    await tester.enterText(find.byType(TextFormField).at(1), 'Rua Central, 100');
    await tester.enterText(find.byType(TextFormField).at(2), '-5');
    await tester.enterText(find.byType(TextFormField).at(3), 'Caixas');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar estabelecimento'));
    await tester.pump();

    expect(find.text('Informe um número válido maior que zero.'), findsOneWidget);
    verifyNever(() => service.addEstablishment(any()));
  });

  test('Establishment model converts to map correctly', () {
    final createdAt = DateTime.utc(2026, 6, 4, 12, 0, 0);
    final establishment = Establishment(
      id: 'id-1',
      name: 'Mercado',
      address: 'Rua A, 123',
      capacity: 15,
      serviceType: 'Caixas',
      adminId: 'admin-1',
      createdAt: createdAt,
    );

    final map = establishment.toMap();

    expect(map['name'], 'Mercado');
    expect(map['address'], 'Rua A, 123');
    expect(map['capacity'], 15);
    expect(map['serviceType'], 'Caixas');
    expect(map['adminId'], 'admin-1');
    expect(map['createdAt'], isA<Timestamp>());
  });
}
