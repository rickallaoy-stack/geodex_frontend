import 'dart:math' as math;
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
      case 'ILLEGAL':
      case 'ILLÉGAL':    return StatutPermis.illegal;
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
  /// Surface approximative du périmètre en hectares.
  /// Les coordonnées du GeoJSON sont en WGS84 ; le calcul est suffisamment
  /// précis pour l'affichage d'un permis, sans inventer une valeur à 0 ha.
  double get superficieHa {
    if (polygone.length < 3) return 0;
    const earthRadiusM = 6371008.8;
    var surfaceM2 = 0.0;
    for (var i = 0; i < polygone.length; i++) {
      final current = polygone[i];
      final next = polygone[(i + 1) % polygone.length];
      final lat1 = current.latitude * 3.141592653589793 / 180;
      final lat2 = next.latitude * 3.141592653589793 / 180;
      final deltaLng = (next.longitude - current.longitude) *
          3.141592653589793 / 180;
      surfaceM2 += deltaLng * (2 + math.sin(lat1) + math.sin(lat2));
    }
    return (surfaceM2.abs() * earthRadiusM * earthRadiusM / 2) / 10000;
  }
}

final List<PermisMinier> permisDemo = [

  // ── MINES EN EXPLOITATION ──────────────────────────────

  // 1. TONGON — Barrick Gold — Nord (9.167, -6.483)
  PermisMinier(
    id: 'ci-001', codePermis: 'PM-CI-2019-001',
    nomEntreprise: 'Barrick Gold (Tongon SA)', minerai: 'OR',
    statut: StatutPermis.valide,
    dateAttribution: DateTime(2019, 3, 12),
    dateExpiration: DateTime(2029, 3, 11),
    centre: const LatLng(9.167, -6.483),
    polygone: [
      LatLng(9.28, -6.60), LatLng(9.28, -6.37),
      LatLng(9.05, -6.37), LatLng(9.05, -6.60),
    ],
  ),

  // 2. BONIKRO / HIRÉ — Allied Gold — Centre (6.40, -5.23)
  PermisMinier(
    id: 'ci-002', codePermis: 'PM-CI-2017-042',
    nomEntreprise: 'Allied Gold (Bonikro SA)', minerai: 'OR',
    statut: StatutPermis.valide,
    dateAttribution: DateTime(2017, 7, 1),
    dateExpiration: DateTime(2027, 6, 30),
    centre: const LatLng(6.40, -5.23),
    polygone: [
      LatLng(6.52, -5.35), LatLng(6.52, -5.11),
      LatLng(6.28, -5.11), LatLng(6.28, -5.35),
    ],
  ),

  // 3. YAOURÉ — Perseus Mining — Centre (6.97, -5.55)
  PermisMinier(
    id: 'ci-003', codePermis: 'PM-CI-2020-015',
    nomEntreprise: 'Perseus Mining (Yaouré SA)', minerai: 'OR',
    statut: StatutPermis.valide,
    dateAttribution: DateTime(2020, 1, 15),
    dateExpiration: DateTime(2030, 1, 14),
    centre: const LatLng(6.97, -5.55),
    polygone: [
      LatLng(7.08, -5.67), LatLng(7.08, -5.43),
      LatLng(6.86, -5.43), LatLng(6.86, -5.67),
    ],
  ),

  // 4. SÉGUÉLA — Fortuna Silver / Roxgold — Nord-Ouest (8.00, -6.67)
  PermisMinier(
    id: 'ci-004', codePermis: 'PM-CI-2021-088',
    nomEntreprise: 'Fortuna Silver Mines (Séguéla)', minerai: 'OR',
    statut: StatutPermis.valide,
    dateAttribution: DateTime(2021, 4, 20),
    dateExpiration: DateTime(2031, 4, 19),
    centre: const LatLng(8.00, -6.67),
    polygone: [
      LatLng(8.12, -6.80), LatLng(8.12, -6.54),
      LatLng(7.88, -6.54), LatLng(7.88, -6.80),
    ],
  ),

  // 5. SISSINGUÉ — Perseus Mining — Nord (9.75, -6.92)
  PermisMinier(
    id: 'ci-005', codePermis: 'PM-CI-2017-031',
    nomEntreprise: 'Perseus Mining (Sissingué SA)', minerai: 'OR',
    statut: StatutPermis.valide,
    dateAttribution: DateTime(2017, 11, 5),
    dateExpiration: DateTime(2027, 11, 4),
    centre: const LatLng(9.75, -6.92),
    polygone: [
      LatLng(9.87, -7.05), LatLng(9.87, -6.79),
      LatLng(9.63, -6.79), LatLng(9.63, -7.05),
    ],
  ),

  // 6. ITY — Endeavour Mining — Ouest (7.52, -7.90)
  PermisMinier(
    id: 'ci-006', codePermis: 'PM-CI-2016-007',
    nomEntreprise: 'Endeavour Mining (Ity SA)', minerai: 'OR',
    statut: StatutPermis.valide,
    dateAttribution: DateTime(2016, 6, 10),
    dateExpiration: DateTime(2026, 6, 9),
    centre: const LatLng(7.52, -7.90),
    polygone: [
      LatLng(7.64, -8.03), LatLng(7.64, -7.77),
      LatLng(7.40, -7.77), LatLng(7.40, -8.03),
    ],
  ),

  // 7. AGBAOU — Endeavour Mining — Centre-Sud (6.32, -5.73)
  PermisMinier(
    id: 'ci-007', codePermis: 'PM-CI-2014-003',
    nomEntreprise: 'Endeavour Mining (Agbaou SA)', minerai: 'OR',
    statut: StatutPermis.valide,
    dateAttribution: DateTime(2014, 2, 1),
    dateExpiration: DateTime(2024, 1, 31),
    centre: const LatLng(6.32, -5.73),
    polygone: [
      LatLng(6.44, -5.86), LatLng(6.44, -5.60),
      LatLng(6.20, -5.60), LatLng(6.20, -5.86),
    ],
  ),

  // 8. HIRÉ — Allied Gold — Sud (5.72, -5.10)
  PermisMinier(
    id: 'ci-008', codePermis: 'PM-CI-2015-022',
    nomEntreprise: 'Allied Gold (Hiré SA)', minerai: 'OR',
    statut: StatutPermis.valide,
    dateAttribution: DateTime(2015, 9, 15),
    dateExpiration: DateTime(2028, 9, 14),
    centre: const LatLng(5.72, -5.10),
    polygone: [
      LatLng(5.84, -5.23), LatLng(5.84, -4.97),
      LatLng(5.60, -4.97), LatLng(5.60, -5.23),
    ],
  ),

  // 9. FETEKRO — Endeavour Mining — Centre-Nord (8.22, -4.83)
  PermisMinier(
    id: 'ci-009', codePermis: 'PM-CI-2022-056',
    nomEntreprise: 'Endeavour Mining (Fetekro SA)', minerai: 'OR',
    statut: StatutPermis.valide,
    dateAttribution: DateTime(2022, 3, 8),
    dateExpiration: DateTime(2032, 3, 7),
    centre: const LatLng(8.22, -4.83),
    polygone: [
      LatLng(8.34, -4.96), LatLng(8.34, -4.70),
      LatLng(8.10, -4.70), LatLng(8.10, -4.96),
    ],
  ),

  // 10. ABUJAR — Tietto Minerals — Ouest (5.88, -7.28)
  PermisMinier(
    id: 'ci-010', codePermis: 'PM-CI-2023-041',
    nomEntreprise: 'Tietto Minerals (Abujar SA)', minerai: 'OR',
    statut: StatutPermis.valide,
    dateAttribution: DateTime(2023, 1, 20),
    dateExpiration: DateTime(2033, 1, 19),
    centre: const LatLng(5.88, -7.28),
    polygone: [
      LatLng(6.00, -7.41), LatLng(6.00, -7.15),
      LatLng(5.76, -7.15), LatLng(5.76, -7.41),
    ],
  ),

  // 11. LAFIGUÉ — Predictive Discovery — Nord (9.40, -5.18)
  PermisMinier(
    id: 'ci-011', codePermis: 'PM-CI-2023-072',
    nomEntreprise: 'Predictive Discovery (Lafigué SA)', minerai: 'OR',
    statut: StatutPermis.valide,
    dateAttribution: DateTime(2023, 6, 14),
    dateExpiration: DateTime(2033, 6, 13),
    centre: const LatLng(9.40, -5.18),
    polygone: [
      LatLng(9.52, -5.31), LatLng(9.52, -5.05),
      LatLng(9.28, -5.05), LatLng(9.28, -5.31),
    ],
  ),

  // 12. DAAPLEU — Endeavour Mining — Ouest (7.80, -8.35)
  PermisMinier(
    id: 'ci-012', codePermis: 'PM-CI-2022-033',
    nomEntreprise: 'Endeavour Mining (Ity-Daapleu)', minerai: 'OR',
    statut: StatutPermis.valide,
    dateAttribution: DateTime(2022, 8, 1),
    dateExpiration: DateTime(2032, 7, 31),
    centre: const LatLng(7.80, -8.35),
    polygone: [
      LatLng(7.92, -8.48), LatLng(7.92, -8.22),
      LatLng(7.68, -8.22), LatLng(7.68, -8.48),
    ],
  ),

  // ── PERMIS SUSPENDUS ──────────────────────────────────

  // 13. BOUNDIALI — Suspendu (nord-ouest)
  PermisMinier(
    id: 'ci-013', codePermis: 'PM-CI-2018-091',
    nomEntreprise: 'SODEMI / Boundiali Mining', minerai: 'OR',
    statut: StatutPermis.suspendu,
    dateAttribution: DateTime(2018, 5, 3),
    dateExpiration: DateTime(2028, 5, 2),
    centre: const LatLng(9.52, -6.48),
    polygone: [
      LatLng(9.64, -6.61), LatLng(9.64, -6.35),
      LatLng(9.40, -6.35), LatLng(9.40, -6.61),
    ],
  ),

  // 14. DIVO — Suspendu (centre-sud)
  PermisMinier(
    id: 'ci-014', codePermis: 'PM-CI-2016-054',
    nomEntreprise: 'GoldMines CI Sarl', minerai: 'OR',
    statut: StatutPermis.suspendu,
    dateAttribution: DateTime(2016, 11, 22),
    dateExpiration: DateTime(2026, 11, 21),
    centre: const LatLng(5.83, -5.36),
    polygone: [
      LatLng(5.95, -5.49), LatLng(5.95, -5.23),
      LatLng(5.71, -5.23), LatLng(5.71, -5.49),
    ],
  ),

  // ── SITES ILLÉGAUX DÉTECTÉS ───────────────────────────

  // 15. Zone illégale — Nord Korhogo
  PermisMinier(
    id: 'ci-015', codePermis: 'ILLEGAL-2024-001',
    nomEntreprise: 'Inconnue', minerai: 'OR',
    statut: StatutPermis.illegal,
    centre: const LatLng(9.83, -5.62),
    polygone: [
      LatLng(9.89, -5.68), LatLng(9.89, -5.56),
      LatLng(9.77, -5.56), LatLng(9.77, -5.68),
    ],
  ),

  // 16. Zone illégale — Ouest Man
  PermisMinier(
    id: 'ci-016', codePermis: 'ILLEGAL-2024-002',
    nomEntreprise: 'Inconnue', minerai: 'OR',
    statut: StatutPermis.illegal,
    centre: const LatLng(7.40, -7.55),
    polygone: [
      LatLng(7.46, -7.61), LatLng(7.46, -7.49),
      LatLng(7.34, -7.49), LatLng(7.34, -7.61),
    ],
  ),

  // 17. Zone illégale — Centre Bouaké
  PermisMinier(
    id: 'ci-017', codePermis: 'ILLEGAL-2025-003',
    nomEntreprise: 'Inconnue', minerai: 'OR',
    statut: StatutPermis.illegal,
    centre: const LatLng(7.69, -5.03),
    polygone: [
      LatLng(7.75, -5.09), LatLng(7.75, -4.97),
      LatLng(7.63, -4.97), LatLng(7.63, -5.09),
    ],
  ),

  // ── MINERAIS NON-AURIFÈRES ────────────────────────────

  // 18. SIPILOU — Nickel/Cobalt — Ouest (7.95, -7.40)
  PermisMinier(
    id: 'ci-018', codePermis: 'PM-CI-2022-098',
    nomEntreprise: 'Sama Nickel Corporation', minerai: 'NICKEL',
    statut: StatutPermis.valide,
    dateAttribution: DateTime(2022, 10, 5),
    dateExpiration: DateTime(2032, 10, 4),
    centre: const LatLng(7.95, -7.40),
    polygone: [
      LatLng(8.07, -7.53), LatLng(8.07, -7.27),
      LatLng(7.83, -7.27), LatLng(7.83, -7.53),
    ],
  ),

  // 19. BIANKOUMA — Lithium — Ouest (7.73, -7.62)
  PermisMinier(
    id: 'ci-019', codePermis: 'PM-CI-2023-112',
    nomEntreprise: 'Critical Minerals CI', minerai: 'LITHIUM',
    statut: StatutPermis.enAttente,
    dateAttribution: DateTime(2023, 11, 30),
    dateExpiration: DateTime(2028, 11, 29),
    centre: const LatLng(7.73, -7.62),
    polygone: [
      LatLng(7.85, -7.75), LatLng(7.85, -7.49),
      LatLng(7.61, -7.49), LatLng(7.61, -7.75),
    ],
  ),

  // 20. GRAND-LAHOU — Sable minéral côtier (5.15, -5.02)
  PermisMinier(
    id: 'ci-020', codePermis: 'PM-CI-2021-067',
    nomEntreprise: 'Minéraux Côtiers CI Sarl', minerai: 'SABLE MINÉRAL',
    statut: StatutPermis.valide,
    dateAttribution: DateTime(2021, 7, 18),
    dateExpiration: DateTime(2031, 7, 17),
    centre: const LatLng(5.15, -5.02),
    polygone: [
      LatLng(5.22, -5.12), LatLng(5.22, -4.92),
      LatLng(5.08, -4.92), LatLng(5.08, -5.12),
    ],
  ),
];
