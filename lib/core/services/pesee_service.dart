import '../network/api_client.dart';

class PeseeService {
  // Envoie une pesée au backend IoT
  static Future<Map<String, dynamic>> envoyerPesee({
    required String capteurId,
    required double poidsMesureKg,
    required double latitude,
    required double longitude,
    required String signatureEquipement,
  }) async {
    try {
      final client = ApiClient();
      final res = await client.post('/api/pesees', body: {
        'capteur_id':           capteurId,
        'poids_mesure_kg':      poidsMesureKg,
        'latitude':             latitude,
        'longitude':            longitude,
        'signature_equipement': signatureEquipement,
      });
      return {
        'success':    true,
        'releve_id':  res['data']['releve_id'],
        'hash':       res['data']['hash_actuel'],
        'statut':     res['data']['statut'],
        'message':    res['message'],
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Récupère la liste des pesées
  static Future<List<Map<String, dynamic>>> fetchPesees() async {
    try {
      final client = ApiClient();
      final res = await client.get('/api/pesees');
      return List<Map<String, dynamic>>.from(res['data'] ?? []);
    } catch (_) {
      return [];
    }
  }

  // Vérifie l'intégrité de la chaîne de hash
  static Future<Map<String, dynamic>> verifierIntegrite() async {
    try {
      final client = ApiClient();
      final res = await client.get('/api/pesees/verify-chain');
      return {
        'integre':  res['integre'] as bool,
        'message':  res['message'] as String,
      };
    } catch (e) {
      return {'integre': false, 'message': e.toString()};
    }
  }

  // Récupère les alertes fraude depuis le backend
  static Future<List<AlerteBackend>> fetchAlertes() async {
    try {
      final client = ApiClient();
      final res = await client.get('/api/pesees/alertes');
      final data = res['data'] as List;
      return data.map((a) => AlerteBackend.fromJson(a)).toList();
    } catch (_) {
      return [];
    }
  }
}

class AlerteBackend {
  final String id;
  final String typeAnomalie;
  final String description;
  final DateTime dateAlerte;
  final double latitude;
  final double longitude;
  final double poidsMesureKg;

  const AlerteBackend({
    required this.id,
    required this.typeAnomalie,
    required this.description,
    required this.dateAlerte,
    required this.latitude,
    required this.longitude,
    required this.poidsMesureKg,
  });

  factory AlerteBackend.fromJson(Map<String, dynamic> j) => AlerteBackend(
    id:            j['id'].toString(),
    typeAnomalie:  j['type_anomalie'] ?? '',
    description:   j['description_detaillee'] ?? '',
    dateAlerte:    DateTime.tryParse(j['date_alerte'] ?? '') ?? DateTime.now(),
    latitude:      (j['latitude'] ?? 0).toDouble(),
    longitude:     (j['longitude'] ?? 0).toDouble(),
    poidsMesureKg: (j['poids_mesure_kg'] ?? 0).toDouble(),
  );

  String get typeLabel {
    switch (typeAnomalie) {
      case 'HORS_ZONE':             return 'Hors zone autorisée';
      case 'SIGNATURE_COMPROMISE':  return 'Signature compromise';
      default:                      return typeAnomalie;
    }
  }
}
