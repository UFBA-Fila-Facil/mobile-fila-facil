import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_fila_facil/models/establishment.dart';
import 'package:mobile_fila_facil/models/queue_model.dart';
import 'package:mobile_fila_facil/services/nearby_establishments_service.dart';

void main() {
  // ── NearbyEstablishment.distanceLabel ──────────────────────────────────────

  group('NearbyEstablishment.distanceLabel', () {
    final baseEst = Establishment(
      id: 'est-1',
      name: 'Teste',
      cep: '00000000',
      address: 'Rua X',
      capacity: 1,
      serviceType: 'Balcão',
      adminId: 'admin',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    test('exibe metros quando distância é menor que 100 m', () {
      final nearby = NearbyEstablishment(
        establishment: baseEst,
        distanceKm: 0.05,
      );
      expect(nearby.distanceLabel, '50 m');
    });

    test('exibe km com uma casa decimal quando distância é 100 m ou mais', () {
      final nearby = NearbyEstablishment(
        establishment: baseEst,
        distanceKm: 1.23,
      );
      expect(nearby.distanceLabel, '1.2 km');
    });

    test('exibe exatamente 100 m como km', () {
      final nearby = NearbyEstablishment(
        establishment: baseEst,
        distanceKm: 0.1,
      );
      expect(nearby.distanceLabel, '0.1 km');
    });
  });

  // ── Establishment.copyWith ─────────────────────────────────────────────────

  group('Establishment.copyWith', () {
    final base = Establishment(
      id: 'id-1',
      name: 'Original',
      cep: '01001000',
      address: 'Rua A, 1',
      capacity: 10,
      serviceType: 'Caixas',
      adminId: 'admin-1',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    test('copia com novo nome mantendo demais campos', () {
      final copy = base.copyWith(name: 'Atualizado');
      expect(copy.name, 'Atualizado');
      expect(copy.id, base.id);
      expect(copy.capacity, base.capacity);
      expect(copy.adminId, base.adminId);
    });

    test('copia com nova capacidade', () {
      final copy = base.copyWith(capacity: 50);
      expect(copy.capacity, 50);
      expect(copy.name, base.name);
    });

    test('copia com localização', () {
      const location = GeoPoint(-23.5, -46.6);
      final copy = base.copyWith(location: location);
      expect(copy.location, location);
    });

    test('cópia sem alterações é igual ao original', () {
      final copy = base.copyWith();
      expect(copy.id, base.id);
      expect(copy.name, base.name);
      expect(copy.cep, base.cep);
      expect(copy.address, base.address);
      expect(copy.capacity, base.capacity);
      expect(copy.serviceType, base.serviceType);
      expect(copy.adminId, base.adminId);
    });
  });

  // ── QueueModel.copyWith ────────────────────────────────────────────────────

  group('QueueModel.copyWith', () {
    final base = QueueModel(
      id: 'q-1',
      establishmentId: 'est-1',
      quantityPeople: 5,
      averageWaitingTime: 10,
      serviceType: 'Caixas',
      active: true,
    );

    test('copia com nova quantidade mantendo demais campos', () {
      final copy = base.copyWith(quantityPeople: 15);
      expect(copy.quantityPeople, 15);
      expect(copy.id, base.id);
      expect(copy.establishmentId, base.establishmentId);
      expect(copy.serviceType, base.serviceType);
    });

    test('copia desativando a fila', () {
      final copy = base.copyWith(active: false);
      expect(copy.active, false);
      expect(copy.quantityPeople, base.quantityPeople);
    });

    test('cópia sem alterações é igual ao original', () {
      final copy = base.copyWith();
      expect(copy.id, base.id);
      expect(copy.establishmentId, base.establishmentId);
      expect(copy.quantityPeople, base.quantityPeople);
      expect(copy.averageWaitingTime, base.averageWaitingTime);
      expect(copy.serviceType, base.serviceType);
      expect(copy.active, base.active);
    });
  });

  // ── QueueModel.toMap ──────────────────────────────────────────────────────

  group('QueueModel.toMap', () {
    test('serializa todos os campos corretamente', () {
      final queue = QueueModel(
        id: 'q-1',
        establishmentId: 'est-1',
        quantityPeople: 8,
        averageWaitingTime: 15,
        serviceType: 'Caixas',
        active: true,
      );

      final map = queue.toMap();

      expect(map['establishmentId'], 'est-1');
      expect(map['quantityPeople'], 8);
      expect(map['averageWaitingTime'], 15);
      expect(map['serviceType'], 'Caixas');
      expect(map['active'], true);
    });

    test('serializa fila inativa', () {
      final queue = QueueModel(
        id: 'q-2',
        establishmentId: 'est-2',
        quantityPeople: 0,
        averageWaitingTime: 0,
        serviceType: 'Balcão',
        active: false,
      );

      final map = queue.toMap();

      expect(map['active'], false);
      expect(map['quantityPeople'], 0);
    });
  });
}
