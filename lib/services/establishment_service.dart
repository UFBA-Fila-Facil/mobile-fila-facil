import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/establishment.dart';

class EstablishmentService {
  final FirebaseFirestore _firestore;

  EstablishmentService([FirebaseFirestore? firestore]) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Establishment> get _collection =>
      _firestore.collection('establishments').withConverter<Establishment>(
            fromFirestore: (snapshot, _) => Establishment.fromDocument(snapshot),
            toFirestore: (establishment, _) => establishment.toMap(),
          );

  Stream<List<Establishment>> watchUserEstablishments(String adminId) {
    return _collection
        .where('adminId', isEqualTo: adminId)
        .snapshots()
        .map((snapshot) {
          final establishments = snapshot.docs.map((doc) => doc.data()).toList();
          establishments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return establishments;
        });
  }

  Future<String> addEstablishment(Establishment establishment) async {
    final docRef = await _collection.add(establishment);
    return docRef.id;
  }

  Future<void> updateEstablishment(Establishment establishment) async {
    await _collection.doc(establishment.id).set(establishment);
  }

  Future<void> deleteEstablishment(String establishmentId) async {
    await _collection.doc(establishmentId).delete();
  }

  Stream<Establishment?> watchEstablishment(String id) {
    return _collection.doc(id).snapshots().map((doc) => doc.exists ? doc.data() : null);
  }

  Future<List<Establishment>> searchEstablishments(String query) async {
    final snapshot = await _collection.get();
    final q = query.toLowerCase().trim();
    return snapshot.docs
        .map((doc) => doc.data())
        .where((est) =>
            est.name.toLowerCase().contains(q) ||
            est.address.toLowerCase().contains(q))
        .toList();
  }
}
