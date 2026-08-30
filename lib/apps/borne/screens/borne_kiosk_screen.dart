import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geodex/core/theme.dart';
import 'package:geodex/core/services/borne_service.dart';

enum EtatBorne { ATTENTE_BADGE, IDENTIFICATION, ATTENTE_PESEE, IMPRESSION, ERREUR }

class BorneKioskScreen extends StatefulWidget {
  const BorneKioskScreen({super.key});

  @override
  State<BorneKioskScreen> createState() => _BorneKioskScreenState();
}

class _BorneKioskScreenState extends State<BorneKioskScreen> {
  final BorneService _service = BorneService();

  EtatBorne _etat = EtatBorne.ATTENTE_BADGE;
  OperateurRFID? _operateur;
  double _poidsG = 0;
  bool _poidsStabilise = false;
  PasseportMineral? _passeport;
  String? _erreur;

  StreamSubscription<LecturePoids>? _pollingPoids;

  Future<void> _demarrerCycle({required String rfidUid}) async {
    if (_etat != EtatBorne.ATTENTE_BADGE) return;

    setState(() => _etat = EtatBorne.IDENTIFICATION);

    final resultat = await _service.scannerBadge(rfidUid: rfidUid);

    if (!resultat.succes) {
      final msg = resultat.code == CodeErreurScan.quotaDepasse &&
              resultat.operateur != null
          ? 'Quota depasse\n${resultat.operateur!.nom}\nRestant : ${resultat.operateur!.quotaJourRestantKg.toStringAsFixed(0)} g'
          : resultat.code == CodeErreurScan.badgeInconnu
              ? 'Badge non reconnu\nUID : $rfidUid'
              : resultat.erreur ?? 'Erreur inconnue';
      _afficherErreur(msg);
      return;
    }

    setState(() => _operateur = resultat.operateur);
    setState(() => _etat = EtatBorne.ATTENTE_PESEE);
    _demarrerPollingPoids();
  }

  void _demarrerPollingPoids() {
    _pollingPoids?.cancel();
    _pollingPoids = _service.ecouterPoids().listen((lecture) {
      if (!mounted) return;
      setState(() {
        _poidsG = lecture.poidsG;
        _poidsStabilise = lecture.stabilise;
      });
      if (lecture.stabilise && _etat == EtatBorne.ATTENTE_PESEE) {
        _pollingPoids?.cancel();
        _genererEtImprimerPasseport();
      }
    });
  }

  Future<void> _genererEtImprimerPasseport() async {
    setState(() => _etat = EtatBorne.IMPRESSION);

    final passeport = await _service.genererPasseport(
      operateur: _operateur!,
      poidsNetKg: _poidsG / 1000,
      latitude: 8.6753,
      longitude: -5.0248,
    );

    if (passeport == null) {
      _afficherErreur("Echec generation du passeport");
      return;
    }

    setState(() => _passeport = passeport);
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    _reinitialiser();
  }

  void _afficherErreur(String message) {
    if (!mounted) return;
    _pollingPoids?.cancel();
    setState(() {
      _etat = EtatBorne.ERREUR;
      _erreur = message;
    });
    Future.delayed(const Duration(seconds: 4), _reinitialiser);
  }

  void _reinitialiser() {
    _pollingPoids?.cancel();
    if (!mounted) return;
    setState(() {
      _etat = EtatBorne.ATTENTE_BADGE;
      _operateur = null;
      _poidsG = 0;
      _poidsStabilise = false;
      _passeport = null;
      _erreur = null;
    });
  }

  Future<void> _devStabiliserPoids() async {
    _pollingPoids?.cancel();
    setState(() => _poidsStabilise = true);
    _genererEtImprimerPasseport();
  }

  @override
  void dispose() {
    _pollingPoids?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SirexeTheme.background,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "GEODEX",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: SirexeTheme.success,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                "SYSTEME DE CERTIFICATION MINIERE",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 48),

              Container(
                width: 540,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                decoration: BoxDecoration(
                  color: SirexeTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _buildContenu(),
                ),
              ),

              const SizedBox(height: 32),
              _buildIndicateurEtapes(),
              const SizedBox(height: 32),
              _buildBoutonsDev(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContenu() {
    switch (_etat) {
      case EtatBorne.ATTENTE_BADGE:
        return Column(
          key: const ValueKey('attente'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.badge_outlined, size: 80, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 24),
            const Text(
              "VEUILLEZ BADGER VOTRE CARTE",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        );

      case EtatBorne.IDENTIFICATION:
        return _operateur == null
            ? Column(
                key: const ValueKey('id-load'),
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(height: 20),
                  Text("Lecture du badge...",
                      style: TextStyle(color: Colors.white38, fontSize: 14)),
                ],
              )
            : Column(
                key: const ValueKey('identification'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user, size: 72, color: SirexeTheme.success),
                  const SizedBox(height: 20),
                  Text(
                    "IDENTITE VALIDEE",
                    style: TextStyle(
                      color: SirexeTheme.success,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _operateur!.nom,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Permis : ${_operateur!.permisId}",
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _barreQuota(
                    label: "Quota journalier",
                    consomme: _operateur!.quotaJourKg - _operateur!.quotaJourRestantKg,
                    total: _operateur!.quotaJourKg,
                    restant: _operateur!.quotaJourRestantKg,
                  ),
                ],
              );

      case EtatBorne.ATTENTE_PESEE:
        return Column(
          key: const ValueKey('pesee'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${_poidsG.toStringAsFixed(2)} g",
              style: TextStyle(
                color: SirexeTheme.success,
                fontSize: 72,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 24,
                    color: SirexeTheme.success.withOpacity(0.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _poidsStabilise
                  ? "PESEE STABILISEE — GENERATION EN COURS..."
                  : "ATTENTE STABILISATION...",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _poidsStabilise ? SirexeTheme.success : Colors.white38,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
            if (_operateur != null) ...[
              const SizedBox(height: 20),
              Text(
                _operateur!.nom,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ],
        );

      case EtatBorne.IMPRESSION:
        return Column(
          key: const ValueKey('impression'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.print, size: 72, color: SirexeTheme.warning),
            const SizedBox(height: 20),
            Text(
              "IMPRESSION DU PASSEPORT",
              style: TextStyle(
                color: SirexeTheme.warning,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            if (_passeport != null) ...[
              const SizedBox(height: 16),
              Text(
                "Poids net : ${(_passeport!.poidsNetKg * 1000).toStringAsFixed(2)} g",
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                "ID : ${_passeport!.id.substring(0, 8).toUpperCase()}...",
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              "Recuperez votre document a la sortie",
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
            ),
          ],
        );

      case EtatBorne.ERREUR:
        return Column(
          key: const ValueKey('erreur'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 72, color: Colors.redAccent),
            const SizedBox(height: 20),
            Text(
              _erreur ?? "Erreur inconnue",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Retour automatique dans 4s...",
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        );
    }
  }

  Widget _barreQuota({
    required String label,
    required double consomme,
    required double total,
    required double restant,
  }) {
    final ratio = (consomme / total).clamp(0.0, 1.0);
    final couleur = ratio > 0.8
        ? Colors.redAccent
        : ratio > 0.6
            ? SirexeTheme.warning
            : SirexeTheme.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(couleur),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "${restant.toStringAsFixed(0)} g restants / ${total.toStringAsFixed(0)} g",
          style: TextStyle(color: couleur, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildIndicateurEtapes() {
    final etapes = [
      _EtapeInfo(EtatBorne.ATTENTE_BADGE, Icons.badge_outlined, "Badge"),
      _EtapeInfo(EtatBorne.IDENTIFICATION, Icons.verified_user, "ID"),
      _EtapeInfo(EtatBorne.ATTENTE_PESEE, Icons.scale, "Pesee"),
      _EtapeInfo(EtatBorne.IMPRESSION, Icons.print, "Impression"),
    ];

    final indexActuel = _etat == EtatBorne.ERREUR
        ? -1
        : EtatBorne.values.indexOf(_etat);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(etapes.length, (i) {
        final actif = i == indexActuel;
        final passe = indexActuel >= 0 && i < indexActuel;
        final couleur = passe
            ? SirexeTheme.success
            : actif
                ? Colors.white70
                : Colors.white12;

        return Row(children: [
          Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(etapes[i].icone, size: 16, color: couleur),
            const SizedBox(height: 4),
            Text(etapes[i].label,
                style: TextStyle(color: couleur, fontSize: 9, letterSpacing: 0.5)),
          ]),
          if (i < etapes.length - 1)
            Container(
              width: 36,
              height: 1,
              margin: const EdgeInsets.only(bottom: 14),
              color: passe ? SirexeTheme.success : Colors.white12,
            ),
        ]);
      }),
    );
  }

  Widget _buildBoutonsDev() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "— SIMULATION BADGES [DEV] —",
          style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontSize: 9,
              letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _boutonBadge(
              label: "Badge KONE",
              sous: "quota OK",
              couleur: SirexeTheme.success,
              rfidUid: 'CARD-A1B2C3',
            ),
            const SizedBox(width: 12),
            _boutonBadge(
              label: "Badge KOUASSI",
              sous: "limite !",
              couleur: SirexeTheme.warning,
              rfidUid: 'CARD-D4E5F6',
            ),
            const SizedBox(width: 12),
            _boutonBadge(
              label: "Badge inconnu",
              sous: "refus",
              couleur: Colors.redAccent,
              rfidUid: 'CARD-ZZZZZZ',
            ),
          ],
        ),
        if (_etat == EtatBorne.ATTENTE_PESEE) ...[
          const SizedBox(height: 14),
          TextButton(
            onPressed: _devStabiliserPoids,
            child: Text(
              "[DEV] Stabiliser poids -> generer passeport",
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }

  Widget _boutonBadge({
    required String label,
    required String sous,
    required Color couleur,
    required String rfidUid,
  }) {
    final actif = _etat == EtatBorne.ATTENTE_BADGE;
    return GestureDetector(
      onTap: actif ? () => _demarrerCycle(rfidUid: rfidUid) : null,
      child: AnimatedOpacity(
        opacity: actif ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: couleur.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(4),
            color: couleur.withOpacity(0.05),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.credit_card, size: 20, color: couleur),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: couleur,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              Text(sous,
                  style: TextStyle(
                      color: couleur.withOpacity(0.6), fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtapeInfo {
  final EtatBorne etat;
  final IconData icone;
  final String label;
  const _EtapeInfo(this.etat, this.icone, this.label);
}
