import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_fila_facil/models/establishment.dart';
import 'package:mobile_fila_facil/models/user_queue_entry.dart';
import 'package:mobile_fila_facil/screens/home_screen.dart';
import 'package:mobile_fila_facil/services/auth_service.dart';
import 'package:mobile_fila_facil/services/establishment_service.dart';
import 'package:mobile_fila_facil/services/nearby_establishments_service.dart';
import 'package:mobile_fila_facil/services/queue_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockEstablishmentService extends Mock implements EstablishmentService {}

class MockQueueService extends Mock implements QueueService {}

class FakeNearbyEstablishmentsService extends Fake
    implements NearbyEstablishmentsService {
  @override
  Future<List<NearbyEstablishment>> getNearbyEstablishments() async => [];
}

Establishment _makeEstablishment({String id = 'est-1'}) => Establishment(
      id: id,
      name: 'Mercado',
      cep: '01001000',
      address: 'Rua A, 1',
      capacity: 25,
      serviceType: 'Caixas',
      adminId: 'admin-1',
      createdAt: DateTime.utc(2026, 1, 1),
    );

UserQueueEntry _makeEntry({String id = 'entry-1', String estId = 'est-1'}) =>
    UserQueueEntry(
      id: id,
      userId: 'user-1',
      establishmentId: estId,
      queueId: 'q-$estId',
      joinedAt: DateTime.utc(2026, 1, 1),
      active: true,
      position: 2,
    );

Widget _buildHome({
  required MockAuthService auth,
  required MockEstablishmentService est,
  required MockQueueService queue,
}) =>
    MaterialApp(
      home: HomeScreen(
        authService: auth,
        establishmentService: est,
        queueService: queue,
        nearbyEstablishmentsService: FakeNearbyEstablishmentsService(),
      ),
    );

void main() {
  group('Queue report flow', () {
    testWidgets('exibe o botão de relatório e abre o formulário', (tester) async {
      final auth = MockAuthService();
      final estService = MockEstablishmentService();
      final queueService = MockQueueService();

      when(() => auth.currentUser).thenReturn(null);
      when(() => queueService.watchUserActiveQueue(any()))
          .thenAnswer((_) => Stream.value(_makeEntry()));
      when(() => estService.watchEstablishment(any()))
          .thenAnswer((_) => Stream.value(_makeEstablishment()));
      when(() => queueService.watchQueueForEstablishment(any()))
          .thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(_buildHome(auth: auth, est: estService, queue: queueService));
      await tester.pumpAndSettle();

      expect(find.text('Reportar fila'), findsOneWidget);

      await tester.tap(find.text('Reportar fila'));
      await tester.pumpAndSettle();

      expect(find.text('Contribua com o estado atual da fila'), findsOneWidget);
      expect(find.text('Tamanho percebido da fila'), findsOneWidget);
      expect(find.text('Tempo aproximado de espera (minutos)'), findsOneWidget);
      expect(find.text('Velocidade de atendimento'), findsOneWidget);
    });

    testWidgets('envia um relato anônimo ao preencher e confirmar o formulário',
        (tester) async {
      final auth = MockAuthService();
      final estService = MockEstablishmentService();
      final queueService = MockQueueService();

      when(() => auth.currentUser).thenReturn(null);
      when(() => queueService.watchUserActiveQueue(any()))
          .thenAnswer((_) => Stream.value(_makeEntry()));
      when(() => estService.watchEstablishment(any()))
          .thenAnswer((_) => Stream.value(_makeEstablishment()));
      when(() => queueService.watchQueueForEstablishment(any()))
          .thenAnswer((_) => Stream.value(null));
      when(() => queueService.submitQueueReport(
            queueId: any(named: 'queueId'),
            establishmentId: any(named: 'establishmentId'),
            perceivedSize: any(named: 'perceivedSize'),
            estimatedWaitTime: any(named: 'estimatedWaitTime'),
            serviceSpeed: any(named: 'serviceSpeed'),
            estimatedCount: any(named: 'estimatedCount'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(_buildHome(auth: auth, est: estService, queue: queueService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reportar fila'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Média').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '12');

      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Normal').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar relato anônimo'));
      await tester.pumpAndSettle();

      verify(() => queueService.submitQueueReport(
            queueId: 'q-est-1',
            establishmentId: 'est-1',
            perceivedSize: 'média',
            estimatedWaitTime: 12,
            serviceSpeed: 'normal',
            estimatedCount: null,
          )).called(1);
    });

    testWidgets('abre o campo de estimativa quando a opção estimada é selecionada',
        (tester) async {
      final auth = MockAuthService();
      final estService = MockEstablishmentService();
      final queueService = MockQueueService();

      when(() => auth.currentUser).thenReturn(null);
      when(() => queueService.watchUserActiveQueue(any()))
          .thenAnswer((_) => Stream.value(_makeEntry()));
      when(() => estService.watchEstablishment(any()))
          .thenAnswer((_) => Stream.value(_makeEstablishment()));
      when(() => queueService.watchQueueForEstablishment(any()))
          .thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(_buildHome(auth: auth, est: estService, queue: queueService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reportar fila'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Estimada').last);
      await tester.pumpAndSettle();

      expect(find.text('Quantas pessoas estão na fila?'), findsOneWidget);
    });
  });
}
