class AlerteModel {
  const AlerteModel({
    required this.id,
    required this.typeAnomalie,
    required this.descriptionDetaillee,
    required this.dateAlerte,
    required this.latitude,
    required this.longitude,
    required this.poidsMesureKg,
  });

  final int id;
  final String typeAnomalie;
  final String descriptionDetaillee;
  final DateTime dateAlerte;
  final double latitude;
  final double longitude;
  final double poidsMesureKg;

  factory AlerteModel.fromJson(Map<String, dynamic> json) => AlerteModel(
        id: json['id'] as int,
        typeAnomalie: json['type_anomalie'] as String,
        descriptionDetaillee: json['description_detaillee'] as String,
        dateAlerte: DateTime.parse(json['date_alerte'] as String),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        poidsMesureKg: double.parse(json['poids_mesure_kg'].toString()),
      );

  String get libelleType {
    switch (typeAnomalie) {
      case 'HORS_ZONE':
        return 'Hors zone';
      case 'SIGNATURE_COMPROMISE':
        return 'Signature compromise';
      default:
        return typeAnomalie;
    }
  }

  String get tempsRelatif {
    final diff = DateTime.now().difference(dateAlerte);
    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }
}
