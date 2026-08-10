// ═══════════════════════════════════════════════════════════════════════════════
// lib/models/terrain_modules.dart
//
// Contrats de données partagés entre le dashboard et les modules terrain.
// Aucune logique métier ici — que des types, des interfaces et des stubs.
// ═══════════════════════════════════════════════════════════════════════════════

// ─── MODULE 1 : PESÉE CAMION ─────────────────────────────────────────────────

/// Résultat d'une session de pesée.
class SessionPesee {
  const SessionPesee({
    required this.id,
    required this.permisId,
    required this.camion,
    required this.tarePoids,       // kg — poids camion à vide
    required this.brutPoids,       // kg — poids camion chargé
    required this.horodatage,
    this.operateur,
    this.notes,
  });

  final String id;
  final String permisId;           // lié à PermisMinier.id
  final String camion;             // immatriculation
  final double tarePoids;
  final double brutPoids;
  final DateTime horodatage;
  final String? operateur;
  final String? notes;

  /// Charge nette extraite (tonnes)
  double get netTonnes => (brutPoids - tarePoids) / 1000;

  /// Résumé pour le dashboard
  Map<String, dynamic> toSummary() => {
    'id': id,
    'permisId': permisId,
    'camion': camion,
    'netTonnes': netTonnes,
    'horodatage': horodatage.toIso8601String(),
  };
}

/// Interface que le service de pesée doit implémenter.
/// Le dashboard consomme cette interface — pas l'implémentation concrète.
abstract class IPeseeService {
  /// Enregistre une nouvelle pesée.
  Future<SessionPesee> enregistrer(SessionPesee session);

  /// Retourne toutes les pesées pour un permis donné.
  Future<List<SessionPesee>> getPourPermis(String permisId);

  /// Total extrait (tonnes) pour un permis sur une période.
  Future<double> totalTonnes({
    required String permisId,
    DateTime? depuis,
    DateTime? jusqu,
  });
}

/// Stub utilisé pendant le dev dashboard — remplacé par l'implémentation réelle.
class PeseeServiceStub implements IPeseeService {
  final List<SessionPesee> _data = [
    SessionPesee(
      id: 'ps-001',
      permisId: 'demo-1',
      camion: 'CI-1234-AB',
      tarePoids: 18000,
      brutPoids: 53000,
      horodatage: DateTime.now().subtract(const Duration(hours: 2)),
      operateur: 'Koné B.',
    ),
    SessionPesee(
      id: 'ps-002',
      permisId: 'demo-1',
      camion: 'CI-5678-CD',
      tarePoids: 17500,
      brutPoids: 49000,
      horodatage: DateTime.now().subtract(const Duration(hours: 5)),
      operateur: 'Touré A.',
    ),
  ];

  @override
  Future<SessionPesee> enregistrer(SessionPesee session) async {
    _data.add(session);
    return session;
  }

  @override
  Future<List<SessionPesee>> getPourPermis(String permisId) async =>
      _data.where((s) => s.permisId == permisId).toList();

  @override
  Future<double> totalTonnes({
    required String permisId,
    DateTime? depuis,
    DateTime? jusqu,
  }) async {
    var total = 0.0;
    for (final s in _data.where((s) => s.permisId == permisId)) {
      total += s.netTonnes;
    }
    return total;
  }
}

// ─── MODULE 2 : CLASSIFICATION ROCHES ────────────────────────────────────────

/// Catégories de roches que le modèle peut retourner.
enum CategorieRoche {
  minerai,   // roche à valeur économique — extraction justifiée
  sterile,   // roche sans valeur — mise en terril
  inconnu,   // confiance insuffisante (< seuil)
}

/// Résultat d'une inférence du modèle de classification.
class ResultatClassification {
  const ResultatClassification({
    required this.categorie,
    required this.confidence,    // 0.0 → 1.0
    required this.horodatage,
    this.permisId,
    this.imageBytes,             // optionnel — pour archivage
    this.scores,                 // scores bruts par classe si disponibles
  });

  final CategorieRoche categorie;
  final double confidence;
  final DateTime horodatage;
  final String? permisId;
  final List<int>? imageBytes;
  final Map<String, double>? scores;  // ex. {'minerai': 0.87, 'sterile': 0.13}

  bool get estFiable => confidence >= 0.75;

  Map<String, dynamic> toSummary() => {
    'categorie': categorie.name,
    'confidence': confidence,
    'horodatage': horodatage.toIso8601String(),
    'permisId': permisId,
  };
}

/// Interface du classificateur — abstraite pour permettre le swap
/// modèle local (tflite) ↔ API distante sans toucher au dashboard.
abstract class IClassificateurRoches {
  /// Classifie une image fournie en bytes JPEG/PNG.
  Future<ResultatClassification> classifier({
    required List<int> imageBytes,
    String? permisId,
  });

  /// Indique si le modèle est chargé et prêt.
  bool get estPret;

  /// Libère les ressources (à appeler dans dispose()).
  Future<void> dispose();
}

/// Stub retournant des résultats aléatoires — pour dev dashboard
/// avant intégration tflite_flutter.
class ClassificateurStub implements IClassificateurRoches {
  @override
  bool get estPret => true;

  @override
  Future<ResultatClassification> classifier({
    required List<int> imageBytes,
    String? permisId,
  }) async {
    // Simule un délai d'inférence réaliste
    await Future.delayed(const Duration(milliseconds: 300));

    // Résultat aléatoire pour la démo
    final isMinerai = DateTime.now().millisecond.isEven;
    return ResultatClassification(
      categorie: isMinerai ? CategorieRoche.minerai : CategorieRoche.sterile,
      confidence: 0.70 + (DateTime.now().millisecond % 25) / 100,
      horodatage: DateTime.now(),
      permisId: permisId,
      scores: isMinerai
          ? {'minerai': 0.87, 'sterile': 0.13}
          : {'minerai': 0.22, 'sterile': 0.78},
    );
  }

  @override
  Future<void> dispose() async {}
}

// ─── REGISTRE DES SERVICES (injection de dépendances légère) ─────────────────
//
// Utilisation dans main.dart :
//
//   TerrainServices.init(
//     pesee: PeseeServiceStub(),            // → remplacer par impl. réelle
//     classificateur: ClassificateurStub(), // → remplacer par TfliteClassificateur()
//   );
//
// Utilisation dans n'importe quel widget :
//
//   final total = await TerrainServices.pesee.totalTonnes(permisId: p.id);
//   final resultat = await TerrainServices.classificateur.classifier(imageBytes: bytes);

class TerrainServices {
  TerrainServices._();

  static late IPeseeService _pesee;
  static late IClassificateurRoches _classificateur;

  static void init({
    required IPeseeService pesee,
    required IClassificateurRoches classificateur,
  }) {
    _pesee = pesee;
    _classificateur = classificateur;
  }

  static IPeseeService get pesee => _pesee;
  static IClassificateurRoches get classificateur => _classificateur;
}
