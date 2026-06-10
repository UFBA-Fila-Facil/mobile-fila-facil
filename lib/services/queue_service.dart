import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/queue_model.dart';

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
}
