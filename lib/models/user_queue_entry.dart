import 'package:cloud_firestore/cloud_firestore.dart';

class UserQueueEntry {
  final String id;
  final String userId;
  final String establishmentId;
  final String queueId;
  final DateTime joinedAt;
  final bool active;
  final int position;

  UserQueueEntry({
    required this.id,
    required this.userId,
    required this.establishmentId,
    required this.queueId,
    required this.joinedAt,
    this.active = true,
    this.position = 0,
  });

  factory UserQueueEntry.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserQueueEntry(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      establishmentId: data['establishmentId'] as String? ?? '',
      queueId: data['queueId'] as String? ?? '',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      active: data['active'] as bool? ?? true,
      position: (data['position'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'userId': userId,
      'establishmentId': establishmentId,
      'queueId': queueId,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'active': active,
      'position': position,
    };
  }
}
