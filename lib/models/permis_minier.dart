import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum StatutPermis { actif, suspendu, expire, illegal }

class PermisMinier {
  final String id;
  final String nom;
  final String societe;
  final StatutPermis statut;
  final String ressource;
  final double superficieHa;
  final DateTime dateExpiration;
  final LatLng centre;
  final List<LatLng> polygone;

  const PermisMinier({
    required this.id,
    required this.nom,
    required this.societe,
    required this.statut,
    required this.ressource,
    required this.superficieHa,
    required this.dateExpiration,
    required this.centre,
    required this.polygone,
  });

  Color get couleur {
    switch (statut) {
      case StatutPermis.actif:     return const Color(0xFF238636);
      case StatutPermis.suspendu:  return const Color(0xFFD29922);
      case StatutPermis.expire:    return const Color(0xFF8B949E);
      case StatutPermis.illegal:   return const Color(0xFFF85149);
    }
  }

  String get statutLabel {
    switch (statut) {
      case StatutPermis.actif:     return 'Actif';
      case StatutPermis.suspendu:  return 'Suspendu';
      case StatutPermis.expire:    return 'Expiré';
      case StatutPermis.illegal:   return 'ILLÉGAL';
    }
  }
}

final List<PermisMinier> permisDemo = [
  PermisMinier(
    id: 'PM-CI-2024-001',
    nom: 'Concession Tongon',
    societe: 'Rangold Resources CI',
    statut: StatutPermis.actif,
    ressource: 'Or',
    superficieHa: 12400,
    dateExpiration: DateTime(2028, 6, 15),
    centre: const LatLng(9.167, -6.483),
    polygone: [
      LatLng(9.28, -6.60), LatLng(9.28, -6.37),
      LatLng(9.05, -6.37), LatLng(9.05, -6.60),
    ],
  ),
  PermisMinier(
    id: 'PM-CI-2024-002',
    nom: 'Mine de Séguéla',
    societe: 'Endeavour Mining',
    statut: StatutPermis.actif,
    ressource: 'Or',
    superficieHa: 8700,
    dateExpiration: DateTime(2029, 3, 20),
    centre: const LatLng(7.967, -6.667),
    polygone: [
      LatLng(8.07, -6.78), LatLng(8.07, -6.56),
      LatLng(7.87, -6.56), LatLng(7.87, -6.78),
    ],
  ),
  PermisMinier(
    id: 'PM-CI-2023-087',
    nom: 'Zone Boundiali Nord',
    societe: 'Inconnue',
    statut: StatutPermis.illegal,
    ressource: 'Or (supposé)',
    superficieHa: 340,
    dateExpiration: DateTime(2020, 1, 1),
    centre: const LatLng(9.52, -6.48),
    polygone: [
      LatLng(9.57, -6.53), LatLng(9.57, -6.43),
      LatLng(9.47, -6.43), LatLng(9.47, -6.53),
    ],
  ),
  PermisMinier(
    id: 'PM-CI-2022-034',
    nom: 'Concession Hire',
    societe: 'Perseus Mining',
    statut: StatutPermis.suspendu,
    ressource: 'Or',
    superficieHa: 5200,
    dateExpiration: DateTime(2026, 11, 10),
    centre: const LatLng(5.733, -4.383),
    polygone: [
      LatLng(5.83, -4.48), LatLng(5.83, -4.29),
      LatLng(5.64, -4.29), LatLng(5.64, -4.48),
    ],
  ),
  PermisMinier(
    id: 'PM-CI-2019-011',
    nom: 'Site Koun-Fao',
    societe: 'Sama Resources',
    statut: StatutPermis.expire,
    ressource: 'Nickel',
    superficieHa: 9800,
    dateExpiration: DateTime(2023, 8, 5),
    centre: const LatLng(7.283, -3.000),
    polygone: [
      LatLng(7.38, -3.10), LatLng(7.38, -2.90),
      LatLng(7.19, -2.90), LatLng(7.19, -3.10),
    ],
  ),
];
