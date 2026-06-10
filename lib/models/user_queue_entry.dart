import 'package:cloud_firestore/cloud_firestore.dart';

class UserQueueEntry {
  final String id;
  final String userId;
  final String establishmentId;
  final DateTime joinedAt;
  final bool active;

  UserQueueEntry({
    required this.id,
    required this.userId,
    required this.establishmentId,
    required this.joinedAt,
    this.active = true,
  });

  factory UserQueueEntry.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserQueueEntry(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      establishmentId: data['establishmentId'] as String? ?? '',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      active: data['active'] as bool? ?? true,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'userId': userId,
      'establishmentId': establishmentId,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'active': active,
    };
  }
}
