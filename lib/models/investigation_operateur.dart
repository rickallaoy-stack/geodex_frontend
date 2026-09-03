import 'package:flutter/material.dart';

enum TypeExploitant { tous, artisanal, semiIndustriel, industriel, nonRepertorie }

extension TypeExploitantExtensions on TypeExploitant {
  String get label {
    switch (this) {
      case TypeExploitant.artisanal:      return 'Artisanal';
      case TypeExploitant.semiIndustriel: return 'Semi-industriel';
      case TypeExploitant.industriel:     return 'Industriel';
      case TypeExploitant.nonRepertorie:  return 'Non répertorié';
      case TypeExploitant.tous:           return 'Tous';
    }
  }

  Color get couleur {
    switch (this) {
      case TypeExploitant.artisanal:      return Colors.yellow;
      case TypeExploitant.semiIndustriel: return Colors.orange;
      case TypeExploitant.industriel:     return Colors.blue;
      case TypeExploitant.nonRepertorie:  return Colors.redAccent;
      case TypeExploitant.tous:           return Colors.white70;
    }
  }

  IconData get icone {
    switch (this) {
      case TypeExploitant.artisanal:      return Icons.person;
      case TypeExploitant.semiIndustriel: return Icons.person_outline;
      case TypeExploitant.industriel:     return Icons.business;
      case TypeExploitant.nonRepertorie:  return Icons.warning_amber_rounded;
      case TypeExploitant.tous:           return Icons.all_inclusive;
    }
  }
}

class OperateurInvestigable {
  final String id;
  final String rfidUid;
  final String nom;
  final String permisId;
  final bool actif;
  final double quotaJourKg;
  final double quotaJourConsommeKg;
  final double quotaMensuelKg;
  final double quotaMensuelConsommeKg;
  final bool quotaDepasse;
  final String permisStatut;
  final String minerai;
  final String entreprise;
  final DateTime? dateExpiration;
  final TypeExploitant type;

  OperateurInvestigable({
    required this.id,
    required this.rfidUid,
    required this.nom,
    required this.permisId,
    required this.actif,
    required this.quotaJourKg,
    required this.quotaJourConsommeKg,
    required this.quotaMensuelKg,
    required this.quotaMensuelConsommeKg,
    required this.quotaDepasse,
    required this.permisStatut,
    required this.minerai,
    required this.entreprise,
    this.dateExpiration,
    required this.type,
  });

  factory OperateurInvestigable.fromJson(Map<String, dynamic> j) {
    final entreprise = j['entreprise'] as String? ?? 'Non renseignée';
    final statut = j['permisStatut'] as String? ?? 'INCONNU';

    TypeExploitant type;
    final e = entreprise.toLowerCase();
    if (statut == 'REVOQUE' || statut == 'SUSPENDU') {
      type = TypeExploitant.nonRepertorie;
    } else if (e.contains('endeavour') || e.contains('barrick')) {
      type = TypeExploitant.industriel;
    } else if (e.contains('allied') || e.contains('touro')) {
      type = TypeExploitant.semiIndustriel;
    } else if (e.contains('artisanal') || e.contains('artisanat')) {
      type = TypeExploitant.artisanal;
    } else {
      type = TypeExploitant.nonRepertorie;
    }

    return OperateurInvestigable(
      id:              j['id']?.toString() ?? '',
      rfidUid:         j['rfidUid'] as String? ?? '',
      nom:             j['nom'] as String? ?? 'Inconnu',
      permisId:        j['permisId'] as String? ?? '',
      actif:           j['actif'] as bool? ?? false,
      quotaJourKg:     (j['quotaJourKg'] as num? ?? 0).toDouble(),
      quotaJourConsommeKg: (j['quotaJourConsommeKg'] as num? ?? 0).toDouble(),
      quotaMensuelKg:  (j['quotaMensuelKg'] as num? ?? 0).toDouble(),
      quotaMensuelConsommeKg: (j['quotaMensuelConsommeKg'] as num? ?? 0).toDouble(),
      quotaDepasse:    j['quotaDepasse'] as bool? ?? false,
      permisStatut:    statut,
      minerai:         j['minerai'] as String? ?? 'Non renseigné',
      entreprise:      entreprise,
      dateExpiration:  j['dateExpiration'] != null
          ? DateTime.tryParse(j['dateExpiration'].toString()) : null,
      type: type,
    );
  }

  double get quotaJourRestant => quotaJourKg - quotaJourConsommeKg;
  double get quotaMensuelRestant => quotaMensuelKg - quotaMensuelConsommeKg;

  String get statutLabel => switch (permisStatut) {
    'VALIDE' => 'Valide',
    'SUSPENDU' => 'Suspendu',
    'REVOQUE' => 'Révoqué',
    'EN_ATTENTE' => 'En attente',
    _ => permisStatut,
  };
}
