import 'package:cloud_firestore/cloud_firestore.dart';

class Establishment {
  final String id;
  final String name;
  final String address;
  final int capacity;
  final String serviceType;
  final String adminId;
  final DateTime createdAt;

  Establishment({
    required this.id,
    required this.name,
    required this.address,
    required this.capacity,
    required this.serviceType,
    required this.adminId,
    required this.createdAt,
  });

  factory Establishment.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Establishment(
      id: doc.id,
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      serviceType: data['serviceType'] as String? ?? '',
      adminId: data['adminId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'address': address,
      'capacity': capacity,
      'serviceType': serviceType,
      'adminId': adminId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
