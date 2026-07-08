import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/queue_model.dart';
import '../models/user_queue_entry.dart';

class QueueReport {
  final String queueId;
  final String establishmentId;
  final String perceivedSize;
  final int estimatedWaitTime;
  final String serviceSpeed;
  final int? estimatedCount;
  final DateTime createdAt;

  QueueReport({
    required this.queueId,
    required this.establishmentId,
    required this.perceivedSize,
    required this.estimatedWaitTime,
    required this.serviceSpeed,
    this.estimatedCount,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'queueId': queueId,
      'establishmentId': establishmentId,
      'perceivedSize': perceivedSize,
      'estimatedWaitTime': estimatedWaitTime,
      'serviceSpeed': serviceSpeed,
      'estimatedCount': estimatedCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'anonymous': true,
    };
  }
}

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

  Future<void> submitQueueReport({
    required String queueId,
    required String establishmentId,
    required String perceivedSize,
    required int estimatedWaitTime,
    required String serviceSpeed,
    int? estimatedCount,
  }) async {
    final report = QueueReport(
      queueId: queueId,
      establishmentId: establishmentId,
      perceivedSize: perceivedSize,
      estimatedWaitTime: estimatedWaitTime,
      serviceSpeed: serviceSpeed,
      estimatedCount: estimatedCount,
      createdAt: DateTime.now().toUtc(),
    );

    final reportRef = _firestore.collection('queue_reports').doc();
    final queueRef = _firestore.collection('queues').doc(queueId);

    await _firestore.runTransaction((transaction) async {
      final queueSnapshot = await transaction.get(queueRef);
      if (!queueSnapshot.exists) {
        throw Exception('Fila não encontrada para este relatório.');
      }

      final currentWait = (queueSnapshot.data()?['averageWaitingTime'] as num?)?.toInt() ?? 0;
      final currentQuantity = (queueSnapshot.data()?['quantityPeople'] as num?)?.toInt() ?? 0;
      final currentServiceType = (queueSnapshot.data()?['serviceType'] as String?) ?? '';

      final updatedWait = _mergeEstimatedWaitTime(
        currentWait: currentWait,
        newEstimate: estimatedWaitTime,
      );
      final updatedQuantity = _mergePerceivedQueueSize(
        currentQuantity: currentQuantity,
        perceivedSize: perceivedSize,
        estimatedCount: estimatedCount,
        serviceSpeed: serviceSpeed,
      );

      transaction.set(reportRef, report.toMap());
      transaction.update(queueRef, {
        'averageWaitingTime': updatedWait,
        'quantityPeople': updatedQuantity,
        'serviceType': currentServiceType.isEmpty ? serviceSpeed : currentServiceType,
      });
    });
  }

  int _mergeEstimatedWaitTime({required int currentWait, required int newEstimate}) {
    if (currentWait <= 0) return newEstimate;
    return ((currentWait + newEstimate) / 2).round();
  }

  int _mergePerceivedQueueSize({
    required int currentQuantity,
    required String perceivedSize,
    int? estimatedCount,
    required String serviceSpeed,
  }) {
    final baseFeedback = _feedbackToQuantity(perceivedSize, estimatedCount);
    final speedAdjustment = _serviceSpeedAdjustment(serviceSpeed);

    if (currentQuantity <= 0) {
      return (baseFeedback + speedAdjustment).clamp(0, 200).toInt();
    }

    final weighted = ((currentQuantity * 0.7) + (baseFeedback * 0.25) + (speedAdjustment * 0.05)).round();
    return weighted.clamp(0, 200).toInt();
  }

  int _feedbackToQuantity(String perceivedSize, int? estimatedCount) {
    if (estimatedCount != null && estimatedCount > 0) {
      return estimatedCount;
    }

    switch (perceivedSize.toLowerCase()) {
      case 'pequena':
        return 2;
      case 'média':
        return 8;
      case 'grande':
        return 16;
      case 'estimada':
        return 10;
      default:
        return 0;
    }
  }

  int _serviceSpeedAdjustment(String serviceSpeed) {
    switch (serviceSpeed.toLowerCase()) {
      case 'rápido':
        return -2;
      case 'normal':
        return 0;
      case 'lento':
        return 3;
      default:
        return 0;
    }
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
