import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

enum CodeErreurScan { badgeInconnu, quotaDepasse, permisExpire, serveurInaccessible, inconnu }

class OperateurRFID {
  final String id;
  final String nom;
  final String permisId;
  final String? permisNumero;
  final DateTime? dateExpiration;
  final String? siteNom;
  final double quotaJourKg;
  final double quotaMensuelKg;
  final double quotaJourRestantKg;
  final double quotaMensuelRestantKg;
  final bool quotaDepasse;

  const OperateurRFID({
    required this.id,
    required this.nom,
    required this.permisId,
    this.permisNumero,
    this.dateExpiration,
    this.siteNom,
    required this.quotaJourKg,
    required this.quotaMensuelKg,
    required this.quotaJourRestantKg,
    required this.quotaMensuelRestantKg,
    required this.quotaDepasse,
  });

  factory OperateurRFID.fromJson(Map<String, dynamic> j) => OperateurRFID(
        id: j['id'],
        nom: j['nom'],
        permisId: j['permisId'],
        permisNumero: j['permisNumero'],
        dateExpiration: j['dateExpiration'] != null
            ? DateTime.tryParse(j['dateExpiration'].toString()) : null,
        siteNom: j['siteNom'] as String?,
        quotaJourKg: (j['quotaJourKg'] as num).toDouble(),
        quotaMensuelKg: (j['quotaMensuelKg'] as num).toDouble(),
        quotaJourRestantKg: (j['quotaJourRestantKg'] as num).toDouble(),
        quotaMensuelRestantKg: (j['quotaMensuelRestantKg'] as num).toDouble(),
        quotaDepasse: j['quotaDepasse'] ?? false,
      );
}

class LecturePoids {
  final double poidsG;
  final bool stabilise;
  final String? erreur;
  const LecturePoids({required this.poidsG, required this.stabilise, this.erreur});

  factory LecturePoids.fromJson(Map<String, dynamic> j) => LecturePoids(
        poidsG: (j['poidsG'] as num).toDouble(),
        stabilise: j['stabilise'] ?? false,
        erreur: j['erreur'] as String?,
      );
}

class EtatMaterielBorne {
  final bool rfid;
  final bool balance;
  final bool imprimante;
  final bool reseau;
  final bool modeDemo;

  const EtatMaterielBorne({
    required this.rfid,
    required this.balance,
    required this.imprimante,
    required this.reseau,
    required this.modeDemo,
  });

  const EtatMaterielBorne.demo()
      : rfid = true,
        balance = true,
        imprimante = true,
        reseau = true,
        modeDemo = true;

  factory EtatMaterielBorne.fromJson(Map<String, dynamic> j) => EtatMaterielBorne(
        rfid: j['rfid'] == true,
        balance: j['balance'] == true,
        imprimante: j['imprimante'] == true,
        reseau: j['reseau'] == true,
        modeDemo: j['modeDemo'] == true,
      );
}

class PasseportMineral {
  final String id;
  final String operateurNom;
  final String permisNumero;
  final double poidsNetKg;
  final int expiration;
  final String qrPayload;
  final String statut;
  final bool horsZone;
  final int distanceZoneM;

  const PasseportMineral({
    required this.id,
    required this.operateurNom,
    required this.permisNumero,
    required this.poidsNetKg,
    required this.expiration,
    required this.qrPayload,
    required this.statut,
    this.horsZone = false,
    this.distanceZoneM = 0,
  });

  factory PasseportMineral.fromJson(Map<String, dynamic> j, String qr) =>
      PasseportMineral(
        id:            j['id'],
        operateurNom:  j['operateurNom'],
        permisNumero:  j['permisNumero'] ?? j['permisId'] ?? '',
        poidsNetKg:    (j['poidsNetKg'] as num).toDouble(),
        expiration:    j['expiration'],
        qrPayload:     qr,
        statut:        j['statut'] ?? 'valide',
        horsZone:      j['horsZone'] ?? false,
        distanceZoneM: j['distanceZoneM'] ?? 0,
      );
}

class ResultatScanRFID {
  final bool succes;
  final CodeErreurScan? code;
  final OperateurRFID? operateur;
  final String? erreur;

  const ResultatScanRFID({
    required this.succes,
    this.code,
    this.operateur,
    this.erreur,
  });

  factory ResultatScanRFID.fromJson(Map<String, dynamic> j) {
    final codeStr = j['code'] as String?;
    CodeErreurScan? code;
    if (codeStr == 'BADGE_INCONNU') code = CodeErreurScan.badgeInconnu;
    if (codeStr == 'QUOTA_DEPASSE') code = CodeErreurScan.quotaDepasse;
    if (codeStr == 'PERMIS_EXPIRE') code = CodeErreurScan.permisExpire;

    return ResultatScanRFID(
      succes: j['succes'] == true,
      code: code,
      operateur: j['operateur'] != null ? OperateurRFID.fromJson(j['operateur']) : null,
      erreur: j['erreur'],
    );
  }
}

class BorneService {
  static final BorneService _instance = BorneService._();
  factory BorneService() => _instance;
  BorneService._();

  final String _base = ApiConfig.baseUrl;

  Future<ResultatScanRFID> scannerBadge({String? rfidUid}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/pesees/bornes/rfid-scan'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'rfidUid': rfidUid ?? 'CARD-SIMULE'}),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ResultatScanRFID.fromJson(data);
      }

      if (res.statusCode == 404 || res.statusCode == 403) {
        final data = jsonDecode(res.body);
        return ResultatScanRFID.fromJson(data);
      }

      return const ResultatScanRFID(
        succes: false,
        code: CodeErreurScan.serveurInaccessible,
        erreur: 'Serveur inaccessible',
      );
    } catch (_) {
      return const ResultatScanRFID(
        succes: false,
        code: CodeErreurScan.serveurInaccessible,
        erreur: 'Erreur réseau',
      );
    }
  }

  Stream<LecturePoids> ecouterPoids({Duration intervalle = const Duration(seconds: 2)}) async* {
    while (true) {
      try {
        final res = await http
            .get(Uri.parse('$_base/api/pesees/bornes/poids'))
            .timeout(const Duration(seconds: 3));

        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode == 200) {
          yield LecturePoids.fromJson(data);
        } else {
          yield LecturePoids(
            poidsG: 0,
            stabilise: false,
            erreur: data['erreur'] as String? ?? 'Balance indisponible',
          );
        }
      } catch (_) {
        yield const LecturePoids(
          poidsG: 0,
          stabilise: false,
          erreur: 'Lecture de la balance indisponible',
        );
      }
      await Future.delayed(intervalle);
    }
  }

  Future<PasseportMineral?> genererPasseport({
    required OperateurRFID operateur,
    required double poidsNetKg,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/pesees/passports/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'operateurId':   operateur.id,
              'operateurNom':  operateur.nom,
              'permisId':      operateur.permisId,
              'permisNumero':  operateur.permisNumero ?? operateur.permisId,
              'poidsNetKg':    poidsNetKg,
              'latitude':      latitude,
              'longitude':     longitude,
              'borneId':       'BORNE-TONGON-01',
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['succes'] == true) {
          return PasseportMineral.fromJson(
              data['passeport'], data['qrPayload']);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<EtatMaterielBorne?> etatMateriel() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/pesees/bornes/etat'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) return null;
      return EtatMaterielBorne.fromJson(jsonDecode(res.body));
    } catch (_) {
      return null;
    }
  }

  Future<bool> imprimerTicket(PasseportMineral passeport) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/pesees/passports/print'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'passeportId': passeport.id}),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200 && jsonDecode(res.body)['succes'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> demarrerPeseeDemo({double? poidsG}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/pesees/bornes/demo/pesee'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({if (poidsG != null) 'poidsG': poidsG}),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200 && jsonDecode(res.body)['succes'] == true;
    } catch (_) {
      return false;
    }
  }
}
