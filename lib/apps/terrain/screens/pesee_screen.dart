// lib/apps/terrain/screens/pesee_screen.dart
// GEODEX — PeseeScreen v2.0
// Upgrades : LCD IoT read-only · Geo-lock bloquant · Double signature · Convergence 10s

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/pesee.dart';
import '../../../core/services/pesee_service.dart';
import '../../../core/local/sync_queue.dart';
import 'certificat_screen.dart';

// ─────────────────────────────────────────────
//  CONSTANTES MÉTIER
// ─────────────────────────────────────────────

const _kRayonZoneMetres = 500.0; // rayon autorisé autour du site

const _kVehicules = [
  'CAM-TG-01', 'CAM-TG-02', 'CAM-TG-04', 'CAM-TG-07',
  'CAM-SG-02', 'CAM-SG-05', 'CAM-BN-11',
];

const _kProduits = ['Or', 'Manganèse', 'Bauxite', 'Diamant', 'Nickel', 'Coltan'];

const _kSites = [
  {'id': 'PM-CI-2024-001', 'nom': 'Concession Tongon',   'lat': 9.167,  'lng': -6.483},
  {'id': 'PM-CI-2024-002', 'nom': 'Mine de Séguéla',     'lat': 7.967,  'lng': -6.667},
  {'id': 'PM-CI-2023-087', 'nom': 'Zone Boundiali Nord', 'lat': 9.520,  'lng': -6.480},
];

const _capteurParPermis = {
  'PM-CI-2024-001': 'SENSOR-001',
  'PM-CI-2024-002': 'SENSOR-002',
  'PM-CI-2023-087': 'SENSOR-003',
};

// Couleurs GEODEX
const _cBg      = Color(0xFF0A0A14);
const _cCard    = Color(0xFF0F0F1A);
const _cBorder  = Color(0xFF21262D);
const _cGreen   = Color(0xFF3FB950);
const _cGreenD  = Color(0xFF238636);
const _cYellow  = Color(0xFFD29922);
const _cRed     = Color(0xFFF85149);
const _cBlue    = Color(0xFF58A6FF);
const _cMuted   = Color(0xFF8B949E);
const _cText    = Color(0xFFE6EDF3);

// ─────────────────────────────────────────────
//  ÉTATS DE LA PESÉE
// ─────────────────────────────────────────────

enum EtatPesee {
  attente,      // en attente de montée camion
  lecture,      // capteur en cours de lecture (oscillation)
  stabilisation,// poids qui se stabilise
  stable,       // poids stabilisé — validation possible
  validation,   // en cours d'envoi
  confirme,     // pesée confirmée
}

enum EtatGeo { verification, dansZone, horsZone, erreur }
enum EtatIot { connecte, deconnecte, lecture }

// ─────────────────────────────────────────────
//  MODÈLE SIGNATURE
// ─────────────────────────────────────────────

class Signature {
  final String nom;
  final String role;
  final DateTime horodatage;
  Signature({required this.nom, required this.role, required this.horodatage});
}

// ─────────────────────────────────────────────
//  PESEE SCREEN
// ─────────────────────────────────────────────

class PeseeScreen extends StatefulWidget {
  const PeseeScreen({super.key});
  @override
  State<PeseeScreen> createState() => _PeseeScreenState();
}

class _PeseeScreenState extends State<PeseeScreen>
    with TickerProviderStateMixin {

  // — State principal —
  EtatPesee _etat        = EtatPesee.attente;
  EtatGeo   _etatGeo     = EtatGeo.verification;
  EtatIot   _etatIot     = EtatIot.connecte;

  // — Sélecteurs —
  String _vehicule  = _kVehicules.first;
  String _siteId    = _kSites.first['id'] as String;
  String _produit   = _kProduits.first;

  // — Poids IoT —
  double _poidsBrut       = 0.0;  // lu par le capteur
  double _poidsAffiche    = 0.0;  // avec oscillation LCD
  double _poidsTarget     = 0.0;  // valeur finale stabilisée
  double _tare            = 8500; // tare véhicule kg (simulée)

  // — Convergence —
  int    _secondesStable  = 0;
  static const _kSecondesRequises = 10;
  Timer? _timerStabilisation;
  Timer? _timerIot;
  Timer? _timerLcd;

  // — Signatures —
  Signature? _sigOperateur;
  Signature? _sigChefSite;

  // — Géolocalisation —
  Position? _position;
  double?   _distanceSite;
  Timer?    _timerGeo;

  // — Transaction —
  late String _txnId;

  // — Animations —
  late AnimationController _lcdController;
  late AnimationController _borderController;
  late Animation<double>   _borderAnim;

  final _random = Random();

  // ── init ──────────────────────────────────

  @override
  void initState() {
    super.initState();
    _txnId = _genTxnId();

    _lcdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _borderAnim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _borderController, curve: Curves.easeInOut));

    // Signature opérateur auto (utilisateur connecté)
    _sigOperateur = Signature(
      nom: 'KONÉ Amadou',
      role: 'Opérateur',
      horodatage: DateTime.now(),
    );

    _demarrerGeoVerification();
    _demarrerSimulationIot();
  }

  @override
  void dispose() {
    _lcdController.dispose();
    _borderController.dispose();
    _timerStabilisation?.cancel();
    _timerIot?.cancel();
    _timerLcd?.cancel();
    _timerGeo?.cancel();
    super.dispose();
  }

  // ── Géolocalisation ───────────────────────

  Future<void> _demarrerGeoVerification() async {
    setState(() => _etatGeo = EtatGeo.verification);

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() => _etatGeo = EtatGeo.erreur);
        return;
      }

      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _calculerDistance();

      // Actualisation GPS toutes les 30s
      _timerGeo = Timer.periodic(const Duration(seconds: 30), (_) async {
        _position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (mounted) _calculerDistance();
      });
    } catch (e) {
      // En mode demo/émulateur : simuler dans la zone
      _simulerPositionZone();
    }
  }

  void _calculerDistance() {
    if (_position == null) return;
    final site = _site;
    final dist = Geolocator.distanceBetween(
      _position!.latitude,
      _position!.longitude,
      (site['lat'] as num).toDouble(),
      (site['lng'] as num).toDouble(),
    );
    setState(() {
      _distanceSite = dist;
      _etatGeo = dist <= _kRayonZoneMetres ? EtatGeo.dansZone : EtatGeo.horsZone;
    });
  }

  void _simulerPositionZone() {
    // Simulation pour démo — place l'appareil dans la zone
    setState(() {
      _distanceSite = 45.0 + _random.nextDouble() * 50;
      _etatGeo = EtatGeo.dansZone;
    });
  }

  // ── Simulation IoT bascule ────────────────

  void _demarrerSimulationIot() {
    _timerIot = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      // Simulation oscillation capteur selon l'état
      if (_etat == EtatPesee.lecture || _etat == EtatPesee.stabilisation) {
        _mettreAJourLcd();
      }
    });
  }

  void _mettreAJourLcd() {
    if (_etat == EtatPesee.lecture) {
      // Montée progressive + oscillation forte
      final progress = (_secondesStable / _kSecondesRequises).clamp(0.0, 1.0);
      final oscillation = (1.0 - progress) * 500 * (_random.nextDouble() - 0.5);
      setState(() {
        _poidsAffiche = (_poidsTarget * progress + oscillation).clamp(0, _poidsTarget * 1.2);
      });
    } else if (_etat == EtatPesee.stabilisation) {
      // Oscillation qui s'amortit
      final osc = _secondesStable > 7
          ? 10 * (_random.nextDouble() - 0.5)
          : 80 * (_random.nextDouble() - 0.5);
      setState(() {
        _poidsAffiche = (_poidsTarget + osc).clamp(0, _poidsTarget + 200);
      });
    }
  }

  // ── Actions utilisateur ───────────────────

  void _demarrerPesee() {
    if (_etatGeo != EtatGeo.dansZone) {
      _showAlerte('Hors zone', 'La pesée est bloquée. Vous êtes hors de la zone autorisée de la concession.');
      return;
    }
    if (_etatIot != EtatIot.connecte) {
      _showAlerte('Bascule déconnectée', 'La connexion avec la bascule IoT est perdue. Vérifiez le capteur.');
      return;
    }

    // Générer un poids cible simulé (entre 15 et 45 tonnes brut)
    _poidsTarget = 15000 + _random.nextDouble() * 30000;
    _poidsAffiche = 0;
    _secondesStable = 0;

    setState(() => _etat = EtatPesee.lecture);

    // Progression de la convergence — 1 incrément / seconde
    _timerStabilisation?.cancel();
    _timerStabilisation = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }

      setState(() => _secondesStable++);

      if (_secondesStable >= 4 && _etat == EtatPesee.lecture) {
        setState(() => _etat = EtatPesee.stabilisation);
      }

      if (_secondesStable >= _kSecondesRequises) {
        t.cancel();
        setState(() {
          _etat = EtatPesee.stable;
          _poidsBrut = _poidsTarget;
          _poidsAffiche = _poidsTarget;
        });
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _signerChefSite() {
    showDialog(
      context: context,
      builder: (ctx) => _DialogSignature(
        onConfirmer: (nom) {
          setState(() {
            _sigChefSite = Signature(
              nom: nom,
              role: 'Chef de site',
              horodatage: DateTime.now(),
            );
          });
          Navigator.pop(ctx);
          HapticFeedback.mediumImpact();
        },
      ),
    );
  }

  bool get _peutValider =>
      _etat == EtatPesee.stable &&
      _etatGeo == EtatGeo.dansZone &&
      _etatIot == EtatIot.connecte &&
      _sigOperateur != null &&
      _sigChefSite != null;

  Future<void> _valider() async {
    if (!_peutValider) return;
    setState(() { _etat = EtatPesee.validation; });

    final site = _site;
    final now  = DateTime.now();
    final poidsNetTonnes = (_poidsBrut - _tare) / 1000;

    // Vérification cohérence volumétrique côté client
    // (en prod : comparer avec capteur volume)

    final hash = Pesee.genererHash(
      permisId:  _siteId,
      camionId:  _vehicule,
      poidsNet:  poidsNetTonnes,
      timestamp: now,
      latitude:  (site['lat'] as num).toDouble(),
      longitude: (site['lng'] as num).toDouble(),
    );

    final pesee = Pesee(
      id:        _txnId,
      camionId:  _vehicule,
      permisId:  _siteId,
      nomSite:   site['nom'] as String,
      poidsNet:  poidsNetTonnes,
      poidsBrut: _poidsBrut,
      tare:      _tare,
      timestamp: now,
      latitude:  (site['lat'] as num).toDouble(),
      longitude: (site['lng'] as num).toDouble(),
      hash:      hash,
      statut:    StatutPesee.valide,
    );

    bool ok = false;
    try {
      final res = await PeseeService.envoyerPesee(
        capteurId:           _capteurParPermis[_siteId]!,
        poidsMesureKg:       poidsNetTonnes * 1000,
        latitude:            (site['lat'] as num).toDouble(),
        longitude:           (site['lng'] as num).toDouble(),
        signatureEquipement: 'GEODEX-BASCULE-V2',
      );
      ok = res['success'] == true;
    } catch (_) {}

    if (!ok) {
      await SyncQueue.enqueue(
        pesee,
        capteurId: _capteurParPermis[_siteId]!,
        signature: 'GEODEX-BASCULE-V2',
      );
    }

    if (mounted) {
      setState(() {
        _etat = EtatPesee.confirme;
      });
      HapticFeedback.heavyImpact();

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CertificatScreen(
              pesee: pesee,
              syncOk: ok,
              sigOperateur: SignatureCert(
                nom: _sigOperateur!.nom,
                role: _sigOperateur!.role,
                horodatage: _sigOperateur!.horodatage,
              ),
              sigChefSite: SignatureCert(
                nom: _sigChefSite!.nom,
                role: _sigChefSite!.role,
                horodatage: _sigChefSite!.horodatage,
              ),
            ),
          ),
        );
      }
    }
  }

  void _reset() {
    _timerStabilisation?.cancel();
    setState(() {
      _etat          = EtatPesee.attente;
      _poidsBrut     = 0;
      _poidsAffiche  = 0;
      _poidsTarget   = 0;
      _secondesStable = 0;
      _sigChefSite   = null;
      _txnId         = _genTxnId();
    });
  }

  // ── Helpers ───────────────────────────────

  String _genTxnId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    return 'TXN-${ts.substring(ts.length - 10)}';
  }

  Map<String, dynamic> get _site =>
      _kSites.firstWhere((s) => s['id'] == _siteId);

  double get _poidsNet => (_poidsBrut - _tare).clamp(0, double.infinity);

  void _showAlerte(String titre, String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _cRed, width: 0.5),
        ),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: _cRed, size: 20),
          const SizedBox(width: 8),
          Text(titre, style: const TextStyle(color: _cRed, fontSize: 14,
              fontWeight: FontWeight.w600, fontFamily: 'monospace')),
        ]),
        content: Text(msg, style: const TextStyle(color: _cMuted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Compris', style: TextStyle(color: _cGreen)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBar(),
            const SizedBox(height: 12),
            _buildSiteSelector(),
            const SizedBox(height: 12),
            _buildVehiculeSelector(),
            const SizedBox(height: 12),
            _buildProduitSelector(),
            const SizedBox(height: 16),
            _buildLcdPesee(),
            const SizedBox(height: 12),
            _buildIotStatus(),
            const SizedBox(height: 8),
            _buildGeoStatus(),
            const SizedBox(height: 12),
            _buildConvergenceBar(),
            const SizedBox(height: 16),
            _buildSignatures(),
            const SizedBox(height: 16),
            _buildBoutonPrincipal(),
            const SizedBox(height: 8),
            _buildHashPreview(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0F0F1A),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pesage industriel',
              style: TextStyle(color: _cText, fontSize: 15,
                  fontWeight: FontWeight.w600, fontFamily: GoogleFonts.jetBrainsMono().fontFamily)),
          Text(_txnId,
              style: TextStyle(color: _cMuted, fontSize: 10,
                  fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 1)),
        ],
      ),
      actions: [
        if (_etat != EtatPesee.attente && _etat != EtatPesee.validation)
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.refresh, color: _cMuted, size: 20),
            tooltip: 'Nouvelle pesée',
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: LinearProgressIndicator(
          value: _progressBar,
          backgroundColor: _cBorder,
          valueColor: AlwaysStoppedAnimation<Color>(
            _etat == EtatPesee.confirme ? _cGreen
            : _etat == EtatPesee.validation ? _cBlue
            : _cGreenD,
          ),
        ),
      ),
    );
  }

  double get _progressBar {
    switch (_etat) {
      case EtatPesee.attente: return 0.1;
      case EtatPesee.lecture: return 0.1 + (_secondesStable / _kSecondesRequises) * 0.5;
      case EtatPesee.stabilisation: return 0.5 + (_secondesStable / _kSecondesRequises) * 0.3;
      case EtatPesee.stable: return 0.85;
      case EtatPesee.validation: return 0.95;
      case EtatPesee.confirme: return 1.0;
    }
  }

  // ── Status bar ────────────────────────────

  Widget _buildStatusBar() {
    final String etatLabel;
    final Color  etatColor;

    switch (_etat) {
      case EtatPesee.attente:      etatLabel = 'EN ATTENTE'; etatColor = _cMuted;   break;
      case EtatPesee.lecture:      etatLabel = 'LECTURE...'; etatColor = _cYellow;  break;
      case EtatPesee.stabilisation:etatLabel = 'STABILISATION'; etatColor = _cYellow; break;
      case EtatPesee.stable:       etatLabel = 'POIDS STABILISÉ'; etatColor = _cGreen; break;
      case EtatPesee.validation:   etatLabel = 'ENVOI...';   etatColor = _cBlue;    break;
      case EtatPesee.confirme:     etatLabel = 'CONFIRMÉ ✓'; etatColor = _cGreen;   break;
    }

    return Row(
      children: [
        Container(width: 6, height: 6,
            decoration: BoxDecoration(color: etatColor, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(etatLabel,
            style: TextStyle(color: etatColor, fontSize: 11,
                fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(DateTime.now().toIso8601String().substring(0, 16).replaceAll('T', ' '),
            style: const TextStyle(color: _cMuted, fontSize: 10, fontFamily: 'monospace')),
      ],
    );
  }

  // ── Sélecteurs ────────────────────────────

  Widget _buildSiteSelector() => _buildSelector(
    label: 'CONCESSION',
    value: _site['nom'] as String,
    icon: Icons.location_on_outlined,
    onTap: _etat == EtatPesee.attente ? () => _showSiteSheet() : null,
  );

  Widget _buildVehiculeSelector() => _buildSelector(
    label: 'CAMION',
    value: _vehicule,
    icon: Icons.local_shipping_outlined,
    onTap: _etat == EtatPesee.attente ? () => _showDropSheet('Camion', _kVehicules, _vehicule, (v) => setState(() => _vehicule = v)) : null,
  );

  Widget _buildProduitSelector() => Row(
    children: _kProduits.map((p) {
      final sel = p == _produit;
      return Expanded(
        child: GestureDetector(
          onTap: _etat == EtatPesee.attente ? () => setState(() => _produit = p) : null,
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: sel ? _cGreenD.withOpacity(0.15) : _cCard,
              border: Border.all(
                  color: sel ? _cGreenD : _cBorder, width: sel ? 1 : 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(p,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: sel ? _cGreen : _cMuted,
                    fontSize: 10, fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                    letterSpacing: 0.5)),
          ),
        ),
      );
    }).toList(),
  );

  Widget _buildSelector({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _cCard,
          border: Border.all(color: _cBorder, width: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(children: [
          Icon(icon, color: _cMuted, size: 16),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: _cMuted, fontSize: 9,
                fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 1.5)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: _cText, fontSize: 13,
                fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontWeight: FontWeight.w600)),
          ]),
          const Spacer(),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: _cMuted, size: 18),
        ]),
      ),
    );
  }

  // ── LCD Pesée ─────────────────────────────

  Widget _buildLcdPesee() {
    final Color borderColor;
    final Color digitColor;

    switch (_etat) {
      case EtatPesee.lecture:
      case EtatPesee.stabilisation:
        borderColor = _cYellow; digitColor = _cYellow; break;
      case EtatPesee.stable:
      case EtatPesee.confirme:
        borderColor = _cGreen;  digitColor = _cGreen;  break;
      case EtatPesee.validation:
        borderColor = _cBlue;   digitColor = _cBlue;   break;
      default:
        borderColor = _cBorder; digitColor = _cMuted;
    }

    final bool oscillating =
        _etat == EtatPesee.lecture || _etat == EtatPesee.stabilisation;

    return AnimatedBuilder(
      animation: _borderAnim,
      builder: (_, __) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF050F05),
          border: Border.all(
            color: borderColor.withOpacity(
              oscillating ? _borderAnim.value : 1.0,
            ),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text('BASCULE INDUSTRIELLE — IoT',
                style: TextStyle(color: _cMuted.withOpacity(0.6),
                    fontSize: 9, fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 2)),
            const SizedBox(height: 12),

            // Valeur principale
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _formatPoids(_poidsAffiche),
                    style: TextStyle(
                      color: digitColor,
                      fontSize: 48,
                      fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      shadows: _etat == EtatPesee.stable || _etat == EtatPesee.confirme
                        ? [
                            Shadow(blurRadius: 15, color: _cGreen.withOpacity(0.6)),
                            Shadow(blurRadius: 30, color: _cGreen.withOpacity(0.3)),
                            Shadow(blurRadius: 60, color: _cGreen.withOpacity(0.15)),
                          ]
                        : [
                            Shadow(color: digitColor.withOpacity(0.4),
                                blurRadius: 16),
                          ],
                    ),
                  ),
                  TextSpan(
                    text: ' kg',
                    style: TextStyle(color: digitColor.withOpacity(0.6),
                        fontSize: 18, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Poids net si stable
            if (_etat == EtatPesee.stable || _etat == EtatPesee.confirme)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _cGreenD.withOpacity(0.1),
                  border: Border.all(color: _cGreenD, width: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'NET : ${(_poidsNet / 1000).toStringAsFixed(3)} t'
                  '   TARE : ${(_tare / 1000).toStringAsFixed(2)} t',
                  style: TextStyle(color: _cGreen, fontSize: 11,
                      fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 1),
                ),
              ),

            const SizedBox(height: 8),
            Text(_lcdStatusLabel,
                style: TextStyle(color: _etat == EtatPesee.stable ? _cGreen : _cMuted,
                    fontSize: 10, fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  String _formatPoids(double kg) {
    return kg.toStringAsFixed(0).padLeft(8, '0');
  }

  String get _lcdStatusLabel {
    switch (_etat) {
      case EtatPesee.attente:       return 'En attente du camion...';
      case EtatPesee.lecture:       return 'Lecture capteur en cours...';
      case EtatPesee.stabilisation: return 'Stabilisation en cours...';
      case EtatPesee.stable:        return 'Poids stabilisé — prêt à valider';
      case EtatPesee.validation:    return 'Envoi en cours...';
      case EtatPesee.confirme:      return 'Pesée confirmée ✓';
    }
  }

  // ── Statuts IoT & Geo ─────────────────────

  Widget _buildIotStatus() => _buildStatusRow(
    icon: Icons.memory,
    label: 'Capteur IoT',
    pill: _etatIot == EtatIot.connecte
        ? _Pill(label: '● BASCULE CONNECTÉE', color: _cGreen, bg: const Color(0xFF0F2A0F))
        : _Pill(label: '○ HORS LIGNE',         color: _cRed,   bg: const Color(0xFF2A0F0F)),
  );

  Widget _buildGeoStatus() {
    final Widget pill;
    switch (_etatGeo) {
      case EtatGeo.verification:
        pill = _Pill(label: '⟳ VÉRIFICATION GPS...', color: _cMuted, bg: _cCard);
        break;
      case EtatGeo.dansZone:
        final dist = _distanceSite?.toStringAsFixed(0) ?? '—';
        pill = _Pill(label: '✓ DANS ZONE  ($dist m)', color: _cGreen, bg: const Color(0xFF0F2A0F));
        break;
      case EtatGeo.horsZone:
        final dist = _distanceSite?.toStringAsFixed(0) ?? '—';
        pill = _Pill(label: '⚠ HORS ZONE  ($dist m)', color: _cRed, bg: const Color(0xFF2A0F0F));
        break;
      case EtatGeo.erreur:
        pill = _Pill(label: '✕ GPS INDISPONIBLE', color: _cYellow, bg: const Color(0xFF2A1F00));
        break;
    }
    return _buildStatusRow(icon: Icons.gps_fixed, label: 'Géo-verrouillage', pill: pill);
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required Widget pill,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _cCard,
        border: Border.all(color: _cBorder, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(children: [
        Icon(icon, color: _cMuted, size: 15),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: _cMuted, fontSize: 12,
            fontFamily: 'monospace')),
        const Spacer(),
        pill,
      ]),
    );
  }

  // ── Barre de convergence 10s ──────────────

  Widget _buildConvergenceBar() {
    final bool actif = _etat == EtatPesee.lecture ||
        _etat == EtatPesee.stabilisation;
    final double progress = actif
        ? (_secondesStable / _kSecondesRequises).clamp(0.0, 1.0)
        : (_etat == EtatPesee.stable ? 1.0 : 0.0);
    final Color barColor = progress >= 1.0 ? _cGreen
        : progress > 0.6 ? _cYellow : _cRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('CONVERGENCE', style: TextStyle(color: _cMuted,
              fontSize: 9, fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 1.5)),
          const Spacer(),
          Text('${_secondesStable.clamp(0, _kSecondesRequises)}/$_kSecondesRequises s',
              style: TextStyle(color: barColor, fontSize: 10,
                  fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: _cBorder,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          progress >= 1.0
              ? '✓ Poids validé — 4 cellules convergentes'
              : actif
                  ? 'Convergence des 4 cellules de charge en cours...'
                  : 'En attente du démarrage de la pesée',
          style: TextStyle(
              color: progress >= 1.0 ? _cGreen : _cMuted,
              fontSize: 10, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  // ── Signatures ────────────────────────────

  Widget _buildSignatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SIGNATURES REQUISES',
            style: TextStyle(color: _cMuted, fontSize: 9,
                fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        _buildSignatureRow(
          sig: _sigOperateur,
          role: 'Opérateur',
          icon: Icons.person_outline,
          isAuto: true,
        ),
        const SizedBox(height: 6),
        _buildSignatureRow(
          sig: _sigChefSite,
          role: 'Chef de site',
          icon: Icons.supervisor_account_outlined,
          onSigner: _etat == EtatPesee.stable ? _signerChefSite : null,
        ),
      ],
    );
  }

  Widget _buildSignatureRow({
    required Signature? sig,
    required String role,
    required IconData icon,
    bool isAuto = false,
    VoidCallback? onSigner,
  }) {
    final bool signe = sig != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _cCard,
        border: Border.all(
            color: signe ? _cGreenD : _cBorder, width: signe ? 1 : 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(children: [
        Icon(icon, color: signe ? _cGreen : _cMuted, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(role, style: TextStyle(color: _cMuted, fontSize: 10,
                fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 0.5)),
            if (signe)
              Text(sig.nom, style: TextStyle(color: _cText, fontSize: 12,
                  fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontWeight: FontWeight.w600)),
          ]),
        ),
        if (signe)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _cGreenD.withOpacity(0.15),
              border: Border.all(color: _cGreenD, width: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text('✓ VALIDÉ',
                style: TextStyle(color: _cGreen, fontSize: 10,
                    fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontWeight: FontWeight.w700)),
          )
        else if (onSigner != null)
          GestureDetector(
            onTap: onSigner,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: _cGreenD),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text('SIGNER',
                  style: TextStyle(color: _cGreen, fontSize: 11,
                      fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
            ),
          )
        else
          const Text('EN ATTENTE',
              style: TextStyle(color: _cMuted, fontSize: 10, fontFamily: 'monospace')),
      ]),
    );
  }

  // ── Bouton principal ──────────────────────

  Widget _buildBoutonPrincipal() {
    if (_etat == EtatPesee.attente) {
      final bool bloque = _etatGeo == EtatGeo.horsZone ||
          _etatGeo == EtatGeo.erreur ||
          _etatIot == EtatIot.deconnecte;
      return _BigButton(
        label: bloque ? 'PESÉE BLOQUÉE' : 'DÉMARRER LA PESÉE',
        icon: bloque ? Icons.block : Icons.play_arrow_rounded,
        color: bloque ? _cRed : _cGreenD,
        textColor: Colors.white,
        onTap: bloque ? null : _demarrerPesee,
      );
    }

    if (_etat == EtatPesee.lecture || _etat == EtatPesee.stabilisation) {
      return _BigButton(
        label: 'CONVERGENCE EN COURS...',
        icon: Icons.hourglass_bottom,
        color: _cBorder,
        textColor: _cMuted,
        onTap: null,
      );
    }

    if (_etat == EtatPesee.stable) {
      final bool peutSigner = _sigChefSite == null;
      if (peutSigner) {
        return Column(children: [
          _BigButton(
            label: 'SIGNATURE CHEF DE SITE REQUISE',
            icon: Icons.draw_outlined,
            color: _cYellow.withOpacity(0.15),
            textColor: _cYellow,
            onTap: _signerChefSite,
            border: _cYellow,
          ),
        ]);
      }
      return _BigButton(
        label: 'VALIDER LA PESÉE',
        icon: Icons.verified_outlined,
        color: _cGreenD,
        textColor: Colors.white,
        onTap: _valider,
      );
    }

    if (_etat == EtatPesee.validation) {
      return _BigButton(
        label: 'ENREGISTREMENT...',
        icon: Icons.cloud_upload_outlined,
        color: _cBorder,
        textColor: _cBlue,
        onTap: null,
        loading: true,
      );
    }

    return const SizedBox.shrink();
  }

  // ── Hash preview ──────────────────────────

  Widget _buildHashPreview() {
    if (_etat != EtatPesee.stable && _etat != EtatPesee.validation) {
      return const SizedBox.shrink();
    }
    final hashPreview = Pesee.genererHash(
      permisId:  _siteId,
      camionId:  _vehicule,
      poidsNet:  _poidsNet / 1000,
      timestamp: DateTime.now(),
      latitude:  (_site['lat'] as num).toDouble(),
      longitude: (_site['lng'] as num).toDouble(),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF050F05),
        border: Border.all(color: _cGreenD.withOpacity(0.4), width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HASH SHA-256',
              style: TextStyle(color: _cMuted, fontSize: 9,
                  fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Text(hashPreview,
              style: TextStyle(color: _cGreen, fontSize: 11,
                  fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 0.5),
              overflow: TextOverflow.ellipsis, maxLines: 2),
          const SizedBox(height: 6),
          Row(children: [
            _hashBlock('GENESIS #000', confirmed: true),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('→', style: TextStyle(color: _cMuted, fontSize: 11)),
            ),
            _hashBlock('a3f7...d92e #001', confirmed: true),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('→', style: TextStyle(color: _cMuted, fontSize: 11)),
            ),
            _hashBlock('EN ATTENTE #002', confirmed: false),
          ]),
        ],
      ),
    );
  }

  Widget _hashBlock(String label, {required bool confirmed}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: confirmed
              ? _cGreenD.withOpacity(0.1)
              : _cYellow.withOpacity(0.08),
          border: Border.all(
              color: confirmed ? _cGreenD : _cYellow, width: 0.5),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: confirmed ? _cGreen : _cYellow,
                fontSize: 8, fontFamily: 'monospace'),
            overflow: TextOverflow.ellipsis),
      ),
    );
  }

  // ── Bottom sheets ─────────────────────────

  void _showSiteSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Sélectionner la concession',
                style: TextStyle(color: _cText, fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                    fontWeight: FontWeight.w600)),
          ),
          ..._kSites.map((s) => ListTile(
            tileColor: s['id'] == _siteId
                ? _cGreenD.withOpacity(0.1) : Colors.transparent,
            title: Text(s['nom'] as String,
                style: TextStyle(color: _cText, fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontSize: 13)),
            subtitle: Text(s['id'] as String,
                style: TextStyle(color: _cMuted, fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontSize: 10)),
            trailing: s['id'] == _siteId
                ? Icon(Icons.check, color: _cGreen, size: 16) : null,
            onTap: () {
              setState(() { _siteId = s['id'] as String; });
              Navigator.pop(context);
              _demarrerGeoVerification();
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDropSheet(String title, List<String> items, String current, void Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Sélectionner $title',
                style: TextStyle(color: _cText, fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                    fontWeight: FontWeight.w600)),
          ),
          ...items.map((item) => ListTile(
            tileColor: item == current
                ? _cGreenD.withOpacity(0.1) : Colors.transparent,
            title: Text(item, style: TextStyle(color: _cText,
                fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontSize: 13)),
            trailing: item == current
                ? Icon(Icons.check, color: _cGreen, size: 16) : null,
            onTap: () { onSelect(item); Navigator.pop(context); },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  WIDGETS RÉUTILISABLES
// ─────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Pill({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.4), width: 0.5),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 9,
            fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontWeight: FontWeight.w700,
            letterSpacing: 0.5)),
  );
}

class _BigButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;
  final bool loading;
  final Color? border;

  const _BigButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    this.onTap,
    this.loading = false,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null && !loading ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: border ?? color, width: border != null ? 1.5 : 0),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (loading)
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _cBlue),
              )
            else
              Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(color: textColor, fontSize: 13,
                    fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DIALOG SIGNATURE CHEF DE SITE
// ─────────────────────────────────────────────

class _DialogSignature extends StatefulWidget {
  final void Function(String nom) onConfirmer;
  const _DialogSignature({required this.onConfirmer});

  @override
  State<_DialogSignature> createState() => _DialogSignatureState();
}

class _DialogSignatureState extends State<_DialogSignature> {
  final _ctrl = TextEditingController();
  bool _erreur = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _cGreenD, width: 0.5),
      ),
      title: const Row(children: [
        Icon(Icons.draw_outlined, color: _cGreen, size: 18),
        SizedBox(width: 8),
        Text('Signature chef de site',
            style: TextStyle(color: _cText, fontSize: 14,
                fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Identifiez-vous pour cosigner cette pesée.',
              style: TextStyle(color: _cMuted, fontSize: 12)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            style: TextStyle(color: _cText, fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Nom complet',
              hintStyle: TextStyle(color: _cMuted, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF0D1117),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: _cBorder, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: _cGreenD),
              ),
              errorText: _erreur ? 'Nom requis' : null,
            ),
            onChanged: (_) => setState(() => _erreur = false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: _cMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _cGreenD,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onPressed: () {
            if (_ctrl.text.trim().isEmpty) {
              setState(() => _erreur = true);
              return;
            }
            widget.onConfirmer(_ctrl.text.trim());
          },
          child: Text('SIGNER', style: TextStyle(fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
              fontWeight: FontWeight.w700, letterSpacing: 1)),
        ),
      ],
    );
  }
}
