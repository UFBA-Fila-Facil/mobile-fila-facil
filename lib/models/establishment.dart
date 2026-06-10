import 'package:cloud_firestore/cloud_firestore.dart';

class Establishment {
  final String id;
  final String name;
  final String address;
  final int capacity;
  final String serviceType;
  final String adminId;
  final DateTime createdAt;
  final GeoPoint? location;

  Establishment({
    required this.id,
    required this.name,
    required this.address,
    required this.capacity,
    required this.serviceType,
    required this.adminId,
    required this.createdAt,
    this.location,
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
      location: data['location'] as GeoPoint?,
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
      if (location != null) 'location': location,
    };
  }

  Establishment copyWith({
    String? id,
    String? name,
    String? address,
    int? capacity,
    String? serviceType,
    String? adminId,
    DateTime? createdAt,
    GeoPoint? location,
  }) {
    return Establishment(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      capacity: capacity ?? this.capacity,
      serviceType: serviceType ?? this.serviceType,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
    );
  }
}
