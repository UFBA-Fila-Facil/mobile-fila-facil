import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/establishment.dart';

class NearbyEstablishment {
  final Establishment establishment;
  final double distanceKm;

  const NearbyEstablishment({required this.establishment, required this.distanceKm});

  String get distanceLabel {
    if (distanceKm < 0.1) return '${(distanceKm * 1000).round()} m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}

class NearbyEstablishmentsService {
  final FirebaseFirestore _firestore;

  static const double _radiusKm = 1.0;
  static const int _maxResults = 5;

  NearbyEstablishmentsService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Position?> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  Future<List<NearbyEstablishment>> getNearbyEstablishments() async {
    final position = await _getCurrentLocation();
    if (position == null) return [];

    final snapshot = await _firestore
        .collection('establishments')
        .withConverter<Establishment>(
          fromFirestore: (snap, _) => Establishment.fromDocument(snap),
          toFirestore: (est, _) => est.toMap(),
        )
        .get();

    final nearby = <NearbyEstablishment>[];

    for (final doc in snapshot.docs) {
      final est = doc.data();
      if (est.location == null) continue;

      final distanceKm = _haversineDistance(
        position.latitude,
        position.longitude,
        est.location!.latitude,
        est.location!.longitude,
      );

      if (distanceKm <= _radiusKm) {
        nearby.add(NearbyEstablishment(establishment: est, distanceKm: distanceKm));
      }
    }

    nearby.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return nearby.take(_maxResults).toList();
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;
}
