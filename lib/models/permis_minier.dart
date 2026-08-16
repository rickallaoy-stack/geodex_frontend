import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum StatutPermis { enAttente, valide, suspendu, revoque, illegal }

class PermisMinier {
  final String id;
  final String codePermis;
  final String nomEntreprise;
  final String minerai;
  final StatutPermis statut;
  final DateTime? dateAttribution;
  final DateTime? dateExpiration;
  final LatLng centre;
  final List<LatLng> polygone;

  const PermisMinier({
    required this.id,
    required this.codePermis,
    required this.nomEntreprise,
    required this.minerai,
    required this.statut,
    this.dateAttribution,
    this.dateExpiration,
    required this.centre,
    required this.polygone,
  });

  factory PermisMinier.fromGeoJson(Map<String, dynamic> feature) {
    final props = feature['properties'] as Map<String, dynamic>;
    final geom   = feature['geometry'] as Map<String, dynamic>;

    List<LatLng> points = [];
    LatLng centre = const LatLng(7.5, -5.5);

    if (geom['type'] == 'MultiPolygon') {
      final coords = geom['coordinates'][0][0] as List;
      points = coords.map<LatLng>((c) =>
        LatLng(c[1].toDouble(), c[0].toDouble())).toList();
      if (points.isNotEmpty) {
        final avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
        final avgLng = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
        centre = LatLng(avgLat, avgLng);
      }
    } else if (geom['type'] == 'Polygon') {
      final coords = geom['coordinates'][0] as List;
      points = coords.map<LatLng>((c) =>
        LatLng(c[1].toDouble(), c[0].toDouble())).toList();
      if (points.isNotEmpty) {
        final avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
        final avgLng = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
        centre = LatLng(avgLat, avgLng);
      }
    }

    return PermisMinier(
      id:             props['id']?.toString() ?? '',
      codePermis:     props['code_permis'] ?? '',
      nomEntreprise:  props['nom_entreprise'] ?? 'Inconnue',
      minerai:        props['minerai'] ?? '',
      statut:         _parseStatut(props['statut']),
      dateAttribution: props['date_attribution'] != null
        ? DateTime.tryParse(props['date_attribution']) : null,
      dateExpiration:  props['date_expiration'] != null
        ? DateTime.tryParse(props['date_expiration']) : null,
      centre:  centre,
      polygone: points,
    );
  }

  static StatutPermis _parseStatut(String? s) {
    switch (s) {
      case 'VALIDE':     return StatutPermis.valide;
      case 'SUSPENDU':   return StatutPermis.suspendu;
      case 'REVOQUE':    return StatutPermis.revoque;
      case 'EN_ATTENTE': return StatutPermis.enAttente;
      default:           return StatutPermis.enAttente;
    }
  }

  Color get couleur {
    switch (statut) {
      case StatutPermis.valide:     return const Color(0xFF238636);
      case StatutPermis.suspendu:   return const Color(0xFFD29922);
      case StatutPermis.revoque:    return const Color(0xFFF85149);
      case StatutPermis.enAttente:  return const Color(0xFF8B949E);
      case StatutPermis.illegal:    return const Color(0xFFF85149);
    }
  }

  String get statutLabel {
    switch (statut) {
      case StatutPermis.valide:     return 'Valide';
      case StatutPermis.suspendu:   return 'Suspendu';
      case StatutPermis.revoque:    return 'Révoqué';
      case StatutPermis.enAttente:  return 'En attente';
      case StatutPermis.illegal:    return 'ILLÉGAL';
    }
  }

  String get nom => codePermis;
  String get societe => nomEntreprise;
  String get ressource => minerai;
  double get superficieHa => 0;
}

final List<PermisMinier> permisDemo = [
  PermisMinier(
    id: 'demo-001', codePermis: 'PM-CI-2024-001',
    nomEntreprise: 'Rangold Resources CI', minerai: 'OR',
    statut: StatutPermis.valide,
    dateExpiration: DateTime(2028, 6, 15),
    centre: const LatLng(9.167, -6.483),
    polygone: [
      LatLng(9.28, -6.60), LatLng(9.28, -6.37),
      LatLng(9.05, -6.37), LatLng(9.05, -6.60),
    ],
  ),
  PermisMinier(
    id: 'demo-002', codePermis: 'PM-CI-2024-002',
    nomEntreprise: 'Endeavour Mining', minerai: 'OR',
    statut: StatutPermis.valide,
    dateExpiration: DateTime(2029, 3, 20),
    centre: const LatLng(7.967, -6.667),
    polygone: [
      LatLng(8.07, -6.78), LatLng(8.07, -6.56),
      LatLng(7.87, -6.56), LatLng(7.87, -6.78),
    ],
  ),
  PermisMinier(
    id: 'demo-003', codePermis: 'PM-CI-2023-087',
    nomEntreprise: 'Inconnue', minerai: 'OR',
    statut: StatutPermis.illegal,
    centre: const LatLng(9.52, -6.48),
    polygone: [
      LatLng(9.57, -6.53), LatLng(9.57, -6.43),
      LatLng(9.47, -6.43), LatLng(9.47, -6.53),
    ],
  ),
];
