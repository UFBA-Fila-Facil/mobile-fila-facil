import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/queue_model.dart';
import '../models/user_queue_entry.dart';

class QueueService {
  final FirebaseFirestore _firestore;

  QueueService([FirebaseFirestore? firestore]) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<QueueModel> get _collection =>
      _firestore.collection('queues').withConverter<QueueModel>(
            fromFirestore: (snapshot, _) => QueueModel.fromDocument(snapshot),
            toFirestore: (queue, _) => queue.toMap(),
          );

  Future<String> addQueue(QueueModel queue) async {
    final docRef = await _collection.add(queue);
    return docRef.id;
  }

  Future<void> updateQueue(QueueModel queue) async {
    await _collection.doc(queue.id).set(queue);
  }

  Future<QueueModel?> getQueueForEstablishment(String establishmentId) async {
    final querySnapshot = await _collection.where('establishmentId', isEqualTo: establishmentId).limit(1).get();
    if (querySnapshot.docs.isEmpty) return null;
    return querySnapshot.docs.first.data();
  }

  Stream<QueueModel?> watchQueueForEstablishment(String establishmentId) {
    return _collection.where('establishmentId', isEqualTo: establishmentId).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data();
    });
  }

  CollectionReference<Map<String, dynamic>> get _userQueueCollection =>
      _firestore.collection('user_queues');

  Future<void> joinQueue(String userId, String establishmentId) async {
    final queueQuery = await _firestore
        .collection('queues')
        .where('establishmentId', isEqualTo: establishmentId)
        .limit(1)
        .get();

    if (queueQuery.docs.isEmpty) {
      throw Exception('Nenhuma fila encontrada para este estabelecimento');
    }

    final queueRef = queueQuery.docs.first.reference;
    final newEntryRef = _userQueueCollection.doc();

    await _firestore.runTransaction((transaction) async {
      final queueSnap = await transaction.get(queueRef);
      final currentCount = (queueSnap.data()?['quantityPeople'] as num?)?.toInt() ?? 0;
      final newPosition = currentCount + 1;

      transaction.update(queueRef, {'quantityPeople': newPosition});
      transaction.set(newEntryRef, {
        'userId': userId,
        'establishmentId': establishmentId,
        'queueId': queueRef.id,
        'joinedAt': Timestamp.now(),
        'active': true,
        'position': newPosition,
      });
    });
  }

  Future<void> leaveQueue(String entryId) async {
    final entryRef = _userQueueCollection.doc(entryId);
    final entrySnap = await entryRef.get();
    final data = entrySnap.data()!;
    final position = (data['position'] as num?)?.toInt() ?? 0;
    final establishmentId = data['establishmentId'] as String? ?? '';
    final queueId = data['queueId'] as String? ?? '';

    final activeEntriesSnapshot = await _userQueueCollection
        .where('establishmentId', isEqualTo: establishmentId)
        .where('active', isEqualTo: true)
        .get();

    final higherPositionEntries = activeEntriesSnapshot.docs
        .where((doc) => ((doc.data()['position'] as num?)?.toInt() ?? 0) > position)
        .toList();

    DocumentReference? queueRef;
    if (queueId.isNotEmpty) {
      queueRef = _firestore.collection('queues').doc(queueId);
    } else {
      final queueQuery = await _firestore
          .collection('queues')
          .where('establishmentId', isEqualTo: establishmentId)
          .limit(1)
          .get();
      if (queueQuery.docs.isNotEmpty) {
        queueRef = queueQuery.docs.first.reference;
      }
    }

    final batch = _firestore.batch();

    batch.update(entryRef, {'active': false});

    if (queueRef != null) {
      batch.update(queueRef, {'quantityPeople': FieldValue.increment(-1)});
    }

    for (final doc in higherPositionEntries) {
      batch.update(doc.reference, {'position': FieldValue.increment(-1)});
    }

    await batch.commit();
  }

  Future<void> serveNextCustomer(String establishmentId) async {
    final activeEntries = await _userQueueCollection
        .where('establishmentId', isEqualTo: establishmentId)
        .where('active', isEqualTo: true)
        .get();

    final queueQuery = await _firestore
        .collection('queues')
        .where('establishmentId', isEqualTo: establishmentId)
        .limit(1)
        .get();

    if (queueQuery.docs.isEmpty) return;
    final queueRef = queueQuery.docs.first.reference;

    final batch = _firestore.batch();

    batch.update(queueRef, {'quantityPeople': FieldValue.increment(-1)});

    for (final doc in activeEntries.docs) {
      final pos = (doc.data()['position'] as num?)?.toInt() ?? 0;
      if (pos == 1) {
        batch.update(doc.reference, {'active': false});
      } else {
        batch.update(doc.reference, {'position': FieldValue.increment(-1)});
      }
    }

    await batch.commit();
  }

  Future<void> addCustomerToQueue(String establishmentId) async {
    final queueQuery = await _firestore
        .collection('queues')
        .where('establishmentId', isEqualTo: establishmentId)
        .limit(1)
        .get();

    if (queueQuery.docs.isEmpty) return;
    final queueRef = queueQuery.docs.first.reference;

    await _firestore.runTransaction((transaction) async {
      final queueSnap = await transaction.get(queueRef);
      final currentCount = (queueSnap.data()?['quantityPeople'] as num?)?.toInt() ?? 0;
      transaction.update(queueRef, {'quantityPeople': currentCount + 1});
    });
  }

  Stream<UserQueueEntry?> watchUserActiveQueue(String userId) {
    return _userQueueCollection
        .where('userId', isEqualTo: userId)
        .where('active', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return UserQueueEntry.fromDocument(
        snapshot.docs.first as DocumentSnapshot<Map<String, dynamic>>,
      );
    });
  }
}
