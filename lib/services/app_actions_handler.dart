import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/establishment.dart';

class AppActionsHandler {
  final FirebaseFirestore _firestore;

  AppActionsHandler([FirebaseFirestore? firestore]) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Processa a URI recebida via deep link/App Actions e atualiza a fila.
  /// Espera query params: establishmentId OR cep OR establishmentName, quantity, wait
  Future<String> handleUri(Uri uri) async {
    final params = uri.queryParameters;

    String? estId = params['establishmentId'] ?? params['establishment_id'];
    final cep = params['cep'];
    final estName = params['establishmentName'] ?? params['name'];

    int? quantity;
    int? wait;
    if (params['quantity'] != null) quantity = int.tryParse(params['quantity']!);
    if (params['quantityPeople'] != null) quantity = int.tryParse(params['quantityPeople']!);
    if (params['wait'] != null) wait = int.tryParse(params['wait']!);
    if (params['averageWaitTime'] != null) wait = int.tryParse(params['averageWaitTime']!);

    if (estId == null) {
      // Try resolve by cep or name
      if (cep != null) {
        final snap = await _firestore.collection('establishments').where('cep', isEqualTo: cep).limit(1).get();
        if (snap.docs.isNotEmpty) estId = snap.docs.first.id;
      } else if (estName != null) {
        final snap = await _firestore.collection('establishments').where('name', isEqualTo: estName).limit(1).get();
        if (snap.docs.isNotEmpty) estId = snap.docs.first.id;
      }
    }

    if (estId == null) throw Exception('Estabelecimento não encontrado (establishmentId/cep/name faltando ou inválido)');

    final queueRef = _firestore.collection('queues').doc(estId);

    final updateData = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (quantity != null) updateData['quantityPeople'] = quantity;
    if (wait != null) updateData['averageWaitTime'] = wait;

    await queueRef.set(updateData, SetOptions(merge: true));

    return 'Fila atualizada: ${updateData['quantityPeople'] ?? '—'} pessoas, tempo ${updateData['averageWaitTime'] ?? '—'} minutos';
  }

  Future<Establishment?> findUserEstablishment({
    required String userId,
    required String establishmentName,
  }) async {
    final snap = await _firestore
        .collection('establishments')
        .where('adminId', isEqualTo: userId)
        .where('name', isEqualTo: establishmentName)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Establishment.fromDocument(snap.docs.first);
  }

  Future<String> updateQueue({
    required String establishmentId,
    int? quantityPeople,
    int? averageWaitTime,
  }) async {
    final queueRef = _firestore.collection('queues');
    final snap = await queueRef
        .where('establishmentId', isEqualTo: establishmentId)
        .limit(1)
        .get();

    final updateData = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (quantityPeople != null) updateData['quantityPeople'] = quantityPeople;
    if (averageWaitTime != null) updateData['averageWaitingTime'] = averageWaitTime;

    if (snap.docs.isEmpty) {
      await queueRef.add({'establishmentId': establishmentId, ...updateData});
    } else {
      await snap.docs.first.reference.set(updateData, SetOptions(merge: true));
    }

    return 'Fila atualizada: ${quantityPeople ?? '—'} pessoas, tempo ${averageWaitTime ?? '—'} minutos';
  }
}
