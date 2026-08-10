import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';

enum StatutPesee { valide, fraudeSuspectee, hachInvalide }

class Pesee {
  final String id;
  final String camionId;
  final String permisId;
  final String nomSite;
  final double poidsNet;    // tonnes
  final double poidsBrut;
  final double tare;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String hash;
  final StatutPesee statut;

  const Pesee({
    required this.id,
    required this.camionId,
    required this.permisId,
    required this.nomSite,
    required this.poidsNet,
    required this.poidsBrut,
    required this.tare,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.hash,
    required this.statut,
  });

  static String genererHash({
    required String permisId,
    required String camionId,
    required double poidsNet,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
  }) {
    final payload =
      '$permisId|$camionId|$poidsNet|${timestamp.millisecondsSinceEpoch}'
      '|${latitude.toStringAsFixed(6)}|${longitude.toStringAsFixed(6)}';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  bool get hashValide {
    final expected = genererHash(
      permisId: permisId,
      camionId: camionId,
      poidsNet: poidsNet,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
    );
    return hash == expected;
  }

  String get statutLabel {
    switch (statut) {
      case StatutPesee.valide:          return 'Valide';
      case StatutPesee.fraudeSuspectee: return 'Fraude suspectée';
      case StatutPesee.hachInvalide:    return 'Hash invalide';
    }
  }

  Color get couleur {
    switch (statut) {
      case StatutPesee.valide:          return const Color(0xFF238636);
      case StatutPesee.fraudeSuspectee: return const Color(0xFFD29922);
      case StatutPesee.hachInvalide:    return const Color(0xFFF85149);
    }
  }
}

List<Pesee> genererPeseesDemo() {
  final now = DateTime.now();

  Pesee creer({
    required String id,
    required String camionId,
    required String permisId,
    required String nomSite,
    required double poidsNet,
    required double tare,
    required int minutesAgo,
    required double lat,
    required double lng,
    bool falsifier = false,
  }) {
    final ts      = now.subtract(Duration(minutes: minutesAgo));
    final brut    = poidsNet + tare;
    var   hash    = Pesee.genererHash(
      permisId: permisId, camionId: camionId,
      poidsNet: poidsNet, timestamp: ts,
      latitude: lat, longitude: lng,
    );
    if (falsifier) hash = hash.replaceRange(0, 8, 'FALSIFIE');

    return Pesee(
      id: id, camionId: camionId, permisId: permisId,
      nomSite: nomSite, poidsNet: poidsNet,
      poidsBrut: brut, tare: tare,
      timestamp: ts, latitude: lat, longitude: lng,
      hash: hash,
      statut: falsifier
        ? StatutPesee.hachInvalide
        : StatutPesee.valide,
    );
  }

  return [
    creer(id: 'PSE-001', camionId: 'CAM-TG-04', permisId: 'PM-CI-2024-001',
      nomSite: 'Concession Tongon', poidsNet: 48.2, tare: 18.5,
      minutesAgo: 8, lat: 9.167, lng: -6.483),
    creer(id: 'PSE-002', camionId: 'CAM-TG-07', permisId: 'PM-CI-2024-001',
      nomSite: 'Concession Tongon', poidsNet: 51.7, tare: 18.5,
      minutesAgo: 22, lat: 9.167, lng: -6.483),
    creer(id: 'PSE-003', camionId: 'CAM-SG-02', permisId: 'PM-CI-2024-002',
      nomSite: 'Mine de Séguéla', poidsNet: 44.1, tare: 17.8,
      minutesAgo: 35, lat: 7.967, lng: -6.667),
    creer(id: 'PSE-004', camionId: 'CAM-BN-11', permisId: 'PM-CI-2023-087',
      nomSite: 'Zone Boundiali Nord', poidsNet: 38.5, tare: 17.2,
      minutesAgo: 47, lat: 9.52, lng: -6.48, falsifier: true),
    creer(id: 'PSE-005', camionId: 'CAM-SG-05', permisId: 'PM-CI-2024-002',
      nomSite: 'Mine de Séguéla', poidsNet: 52.3, tare: 18.5,
      minutesAgo: 63, lat: 7.967, lng: -6.667),
    creer(id: 'PSE-006', camionId: 'CAM-TG-02', permisId: 'PM-CI-2024-001',
      nomSite: 'Concession Tongon', poidsNet: 49.8, tare: 18.5,
      minutesAgo: 78, lat: 9.167, lng: -6.483),
  ];
}
