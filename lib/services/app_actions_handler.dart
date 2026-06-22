import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/establishment.dart';
import '../models/user_queue_entry.dart';
import 'queue_service.dart';

class AppActionsHandler {
  final FirebaseFirestore _firestore;
  late final QueueService _queueService;

  AppActionsHandler([FirebaseFirestore? firestore, QueueService? queueService])
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _queueService = queueService ?? QueueService(_firestore);
  }

  /// Normaliza texto: minúsculas, sem acentos, espaços colapsados.
  static String _normalize(String input) {
    var text = input.toLowerCase().trim();
    const accented = 'àáâãäåæçèéêëìíîïðñòóôõöøùúûüýÿ';
    const plain    = 'aaaaaaeceeeeiiiidnoooooouuuuyy';
    for (var i = 0; i < accented.length; i++) {
      text = text.replaceAll(accented[i], plain[i]);
    }
    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Busca estabelecimento do usuário por ID ou nome (sem distinção de
  /// maiúsculas, acentos ou espaçamento).
  Future<Establishment?> findUserEstablishment({
    required String userId,
    String? establishmentId,
    String? establishmentName,
  }) async {
    if (establishmentId != null && establishmentId.isNotEmpty) {
      final doc = await _firestore
          .collection('establishments')
          .doc(establishmentId)
          .get();
      if (!doc.exists) return null;
      final est = Establishment.fromDocument(doc);
      return est.adminId == userId ? est : null;
    }
    if (establishmentName != null && establishmentName.isNotEmpty) {
      final snap = await _firestore
          .collection('establishments')
          .where('adminId', isEqualTo: userId)
          .get();
      final normalized = _normalize(establishmentName);
      for (final doc in snap.docs) {
        final est = Establishment.fromDocument(doc);
        if (_normalize(est.name) == normalized) return est;
      }
      return null;
    }
    return null;
  }

  /// Busca um estabelecimento pelo ID sem filtrar por admin.
  Future<Establishment?> getEstablishmentById(String id) async {
    final doc =
        await _firestore.collection('establishments').doc(id).get();
    if (!doc.exists) return null;
    return Establishment.fromDocument(doc);
  }

  /// Retorna a entrada ativa do usuário na fila, se houver.
  Future<UserQueueEntry?> getUserActiveEntry(String userId) async {
    final snap = await _firestore
        .collection('user_queues')
        .where('userId', isEqualTo: userId)
        .where('active', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return UserQueueEntry.fromDocument(
      snap.docs.first as DocumentSnapshot<Map<String, dynamic>>,
    );
  }

  Future<void> serveNextCustomer(String establishmentId) =>
      _queueService.serveNextCustomer(establishmentId);

  Future<void> addCustomerToQueue(String establishmentId) =>
      _queueService.addCustomerToQueue(establishmentId);

  Future<void> joinQueue(String userId, String establishmentId) =>
      _queueService.joinQueue(userId, establishmentId);

  Future<void> leaveQueue(String entryId) =>
      _queueService.leaveQueue(entryId);

  // ── legado: usado pelo deep link /updateQueue ───────────────────────────

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

    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (quantityPeople != null) updateData['quantityPeople'] = quantityPeople;
    if (averageWaitTime != null) {
      updateData['averageWaitingTime'] = averageWaitTime;
    }

    if (snap.docs.isEmpty) {
      await queueRef.add({'establishmentId': establishmentId, ...updateData});
    } else {
      await snap.docs.first.reference.set(updateData, SetOptions(merge: true));
    }

    return 'Fila atualizada: ${quantityPeople ?? '—'} pessoas, '
        'tempo ${averageWaitTime ?? '—'} minutos';
  }

  Future<String> handleUri(Uri uri) async {
    final params = uri.queryParameters;

    String? estId =
        params['establishmentId'] ?? params['establishment_id'];
    final cep = params['cep'];
    final estName = params['establishmentName'] ?? params['name'];

    int? quantity;
    int? wait;
    if (params['quantity'] != null) {
      quantity = int.tryParse(params['quantity']!);
    }
    if (params['quantityPeople'] != null) {
      quantity = int.tryParse(params['quantityPeople']!);
    }
    if (params['wait'] != null) wait = int.tryParse(params['wait']!);
    if (params['averageWaitTime'] != null) {
      wait = int.tryParse(params['averageWaitTime']!);
    }

    if (estId == null) {
      if (cep != null) {
        final snap = await _firestore
            .collection('establishments')
            .where('cep', isEqualTo: cep)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) estId = snap.docs.first.id;
      } else if (estName != null) {
        final snap = await _firestore
            .collection('establishments')
            .where('name', isEqualTo: estName)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) estId = snap.docs.first.id;
      }
    }

    if (estId == null) {
      throw Exception(
          'Estabelecimento não encontrado (establishmentId/cep/name faltando ou inválido)');
    }

    final queueDocRef = _firestore.collection('queues').doc(estId);
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (quantity != null) updateData['quantityPeople'] = quantity;
    if (wait != null) updateData['averageWaitTime'] = wait;

    await queueDocRef.set(updateData, SetOptions(merge: true));

    return 'Fila atualizada: ${updateData['quantityPeople'] ?? '—'} pessoas, '
        'tempo ${updateData['averageWaitTime'] ?? '—'} minutos';
  }
}
