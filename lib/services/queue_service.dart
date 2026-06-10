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
    await _userQueueCollection.add({
      'userId': userId,
      'establishmentId': establishmentId,
      'joinedAt': Timestamp.now(),
      'active': true,
    });
  }

  Future<void> leaveQueue(String entryId) async {
    await _userQueueCollection.doc(entryId).update({'active': false});
  }

  Stream<UserQueueEntry?> watchUserActiveQueue(String userId) {
    return _userQueueCollection
        .where('userId', isEqualTo: userId)
        .where('active', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      final data = doc.data();
      return UserQueueEntry(
        id: doc.id,
        userId: data['userId'] as String? ?? '',
        establishmentId: data['establishmentId'] as String? ?? '',
        joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        active: data['active'] as bool? ?? true,
      );
    });
  }
}
