import 'package:cloud_firestore/cloud_firestore.dart';

class QueueModel {
  final String id;
  final String establishmentId;
  final int quantityPeople;
  final int averageWaitingTime;
  final String serviceType;
  final bool active;

  QueueModel({
    required this.id,
    required this.establishmentId,
    required this.quantityPeople,
    required this.averageWaitingTime,
    required this.serviceType,
    this.active = true,
  });

  factory QueueModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return QueueModel(
      id: doc.id,
      establishmentId: data['establishmentId'] as String? ?? '',
      quantityPeople: (data['quantityPeople'] as num?)?.toInt() ?? 0,
      averageWaitingTime: (data['averageWaitingTime'] as num?)?.toInt() ?? 0,
      serviceType: data['serviceType'] as String? ?? '',
      active: data['active'] as bool? ?? true,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'establishmentId': establishmentId,
      'quantityPeople': quantityPeople,
      'averageWaitingTime': averageWaitingTime,
      'serviceType': serviceType,
      'active': active,
    };
  }

  QueueModel copyWith({
    String? id,
    String? establishmentId,
    int? quantityPeople,
    int? averageWaitingTime,
    String? serviceType,
    bool? active,
  }) {
    return QueueModel(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      quantityPeople: quantityPeople ?? this.quantityPeople,
      averageWaitingTime: averageWaitingTime ?? this.averageWaitingTime,
      serviceType: serviceType ?? this.serviceType,
      active: active ?? this.active,
    );
  }
}
