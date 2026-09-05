import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geodex/core/services/borne_service.dart';
import 'package:geodex/core/theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum EtatBorne { attenteBadge, identification, attentePesee, impression, erreur }

class BorneKioskScreen extends StatefulWidget {
  const BorneKioskScreen({super.key});

  @override
  State<BorneKioskScreen> createState() => _BorneKioskScreenState();
}

class _BorneKioskScreenState extends State<BorneKioskScreen> {
  final BorneService _service = BorneService();
  EtatBorne _etat = EtatBorne.attenteBadge;
  EtatMaterielBorne _materiel = const EtatMaterielBorne.demo();
  OperateurRFID? _operateur;
  PasseportMineral? _passeport;
  StreamSubscription<LecturePoids>? _poidsSubscription;
  Timer? _materielTimer;
  double _poidsG = 0;
  double? _poidsVerrouilleG;
  bool _poidsStabilise = false;
  bool _impressionEnCours = false;
  bool _ticketImprime = false;
  bool _modeDemoVisible = false;
  bool _sessionDemo = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    try {
      _rafraichirMateriel();
      _materielTimer = Timer.periodic(const Duration(seconds: 5), (_) => _rafraichirMateriel());
    } catch (e) {
      debugPrint('Erreur initState: $e');
    }
  }

  Future<void> _rafraichirMateriel() async {
    final etat = await _service.etatMateriel();
    if (mounted && etat != null) setState(() => _materiel = etat);
  }

  Future<void> _demarrerCycle(String uid, {bool demo = false}) async {
    if (_etat != EtatBorne.attenteBadge) return;
    if (!demo && (!_materiel.rfid || !_materiel.reseau)) {
      _afficherErreur(!_materiel.rfid ? 'Lecteur RFID indisponible' : 'Connexion a la passerelle indisponible');
      return;
    }
    setState(() => _etat = EtatBorne.identification);
    SystemSound.play(SystemSoundType.click);
    final resultat = await _service.scannerBadge(rfidUid: uid);
    if (!mounted) return;
    if (!resultat.succes) {
      final message = resultat.code == CodeErreurScan.quotaDepasse && resultat.operateur != null
          ? 'Quota atteint pour ${resultat.operateur!.nom}\n${resultat.operateur!.quotaJourRestantKg.toStringAsFixed(0)} g disponibles'
          : resultat.code == CodeErreurScan.permisExpire && resultat.operateur != null
              ? 'Permis expiré — ${resultat.operateur!.nom}\nPermis : ${resultat.operateur!.permisNumero ?? resultat.operateur!.permisId}\nExpire : ${_formatDateCourt(resultat.operateur!.dateExpiration)}'
              : resultat.code == CodeErreurScan.badgeInconnu
                  ? 'Badge non reconnu'
                  : resultat.erreur ?? 'Identification impossible';
      _afficherErreur(message);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _operateur = resultat.operateur;
      _etat = EtatBorne.attentePesee;
      _sessionDemo = demo;
    });
    if (demo && !await _service.demarrerPeseeDemo()) {
      _afficherErreur('Simulation indisponible : backend non joignable');
      return;
    }
    _ecouterPoids();
  }

  void _ecouterPoids() {
    _poidsSubscription?.cancel();
    _poidsSubscription = _service.ecouterPoids().listen((lecture) {
      if (!mounted || _etat != EtatBorne.attentePesee) return;
      if (lecture.erreur != null) {
        _afficherErreur(lecture.erreur!);
        return;
      }
      setState(() {
        _poidsG = lecture.poidsG;
        _poidsStabilise = lecture.stabilise;
      });
      if (lecture.stabilise) {
        _poidsSubscription?.cancel();
        setState(() => _poidsVerrouilleG = lecture.poidsG);
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.mediumImpact();
        _genererEtImprimerPasseport();
      }
    });
  }

  Future<void> _genererEtImprimerPasseport() async {
    if (_operateur == null || _poidsVerrouilleG == null) return;
    setState(() => _etat = EtatBorne.impression);
    final passeport = await _service.genererPasseport(
      operateur: _operateur!,
      poidsNetG: _poidsVerrouilleG!,
      latitude: 9.167,
      longitude: -6.483,
    );
    if (!mounted) return;
    if (passeport == null) {
      _afficherErreur('Generation du passeport impossible');
      return;
    }
    setState(() {
      _passeport = passeport;
      _impressionEnCours = true;
    });
    final imprime = _sessionDemo || (_materiel.imprimante && await _service.imprimerTicket(passeport));
    if (!mounted) return;
    if (!imprime) {
      _afficherErreur('Imprimante thermique indisponible');
      return;
    }
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    setState(() {
      _impressionEnCours = false;
      _ticketImprime = true;
    });
    Future.delayed(const Duration(seconds: 5), _reinitialiser);
  }

  void _afficherErreur(String message) {
    _poidsSubscription?.cancel();
    SystemSound.play(SystemSoundType.alert);
    if (!mounted) return;
    setState(() {
      _etat = EtatBorne.erreur;
      _erreur = message;
    });
    // Un passeport signé reste affiché : l'utilisateur doit pouvoir scanner
    // le QR avant de démarrer une nouvelle transaction.
    if (_passeport == null) {
      Future.delayed(const Duration(seconds: 4), _reinitialiser);
    }
  }

  void _reinitialiser() {
    _poidsSubscription?.cancel();
    if (!mounted) return;
    setState(() {
      _etat = EtatBorne.attenteBadge;
      _operateur = null;
      _passeport = null;
      _poidsG = 0;
      _poidsVerrouilleG = null;
      _poidsStabilise = false;
      _impressionEnCours = false;
      _ticketImprime = false;
      _sessionDemo = false;
      _erreur = null;
    });
  }

  String _formatDateCourt(DateTime? dt) => dt == null
      ? '—'
      : '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  void _simulerStabilisation() {
    if (_etat != EtatBorne.attentePesee) return;
    _poidsSubscription?.cancel();
    setState(() {
      _poidsG = _poidsG == 0 ? 24.65 : _poidsG;
      _poidsStabilise = true;
      _poidsVerrouilleG = _poidsG;
    });
    _genererEtImprimerPasseport();
  }

  @override
  void dispose() {
    _poidsSubscription?.cancel();
    _materielTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071714), Color(0xFF0B1110), Color(0xFF030706)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final large = constraints.maxWidth >= 860;
              return Column(
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1A17),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: large
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(width: 310, child: _machinePanel()),
                                  Expanded(child: _sessionPanel()),
                                ],
                              )
                            : Column(
                                children: [
                                  SizedBox(height: 260, child: _machinePanel()),
                                  Expanded(child: _sessionPanel()),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _demoPanel(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header() => Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: SirexeTheme.success.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SirexeTheme.success.withOpacity(0.35)),
            ),
            child: Icon(Icons.account_balance_rounded, color: SirexeTheme.success),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GEODEX', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: 2.5)),
                SizedBox(height: 2),
                Text('BORNE DE CERTIFICATION MINIERE', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.2)),
              ],
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: _pill(
                Icons.cloud_done_outlined,
                _materiel.reseau ? 'PASSERELLE EN LIGNE' : 'HORS LIGNE',
                _materiel.reseau ? SirexeTheme.success : Colors.redAccent,
              ),
            ),
          ),
        ],
      );

  Widget _machinePanel() {
    final color = _etatColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), const Color(0xFF10211D)],
        ),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow('ETAT DE LA BORNE'),
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                  border: Border.all(color: color.withOpacity(0.50), width: 2),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.20), blurRadius: 28, spreadRadius: 4)],
                ),
                child: Icon(_etatIcon, color: color, size: 56),
              ),
            ),
            const SizedBox(height: 20),
            Center(child: Text(_etatLabel, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1))),
            const SizedBox(height: 7),
            Center(child: Text(_etatHint, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4))),
            const SizedBox(height: 28),
            Divider(color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 16),
            _eyebrow('MATERIEL'),
            const SizedBox(height: 12),
            _materielLigne(Icons.contactless_rounded, 'Lecteur RFID', _materiel.rfid),
            _materielLigne(Icons.scale_rounded, 'Balance HX711', _materiel.balance),
            _materielLigne(Icons.print_outlined, 'Imprimante thermique', _materiel.imprimante),
            _materielLigne(Icons.wifi_rounded, 'Reseau passerelle', _materiel.reseau),
            const SizedBox(height: 18),
            _steps(),
          ],
        ),
      ),
    );
  }

  Widget _sessionPanel() => Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(width: 4, height: 24, decoration: BoxDecoration(color: _etatColor, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _etat == EtatBorne.impression ? 'Passeport mineral' : 'Nouvelle pesee',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _contenu(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _contenu() {
    switch (_etat) {
      case EtatBorne.attenteBadge:
        return _emptyState('badge', Icons.contactless_rounded, 'PRESENTEZ VOTRE CARTE', 'Approchez votre badge RFID du lecteur.', SirexeTheme.success);
      case EtatBorne.identification:
        return Column(key: const ValueKey('identification'), mainAxisSize: MainAxisSize.min, children: [const SizedBox(width: 44, height: 44, child: CircularProgressIndicator(strokeWidth: 3)), const SizedBox(height: 22), const Text('Verification de votre identite...', style: TextStyle(color: Colors.white70, fontSize: 16))]);
      case EtatBorne.attentePesee:
        return _peseeView();
      case EtatBorne.impression:
        return _ticketView();
      case EtatBorne.erreur:
        return _erreurView();
    }
  }

  /// Si le passeport a déjà été signé, une panne d'imprimante ne doit pas
  /// empêcher l'opérateur de le récupérer au comptoir.
  Widget _erreurView() {
    final passeport = _passeport;
    if (passeport == null) {
      return _emptyState(
        'erreur',
        Icons.error_outline_rounded,
        'TRANSACTION REFUSEE',
        _erreur ?? 'Erreur inconnue',
        Colors.redAccent,
      );
    }

    final idCourt = passeport.id.length >= 8
        ? passeport.id.substring(0, 8).toUpperCase()
        : passeport.id.toUpperCase();
    return Column(
      key: const ValueKey('erreur-sauvetage'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.print_disabled_rounded,
          color: SirexeTheme.warning,
          size: 60,
        ),
        const SizedBox(height: 16),
        const Text(
          'IMPRIMANTE INDISPONIBLE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SirexeTheme.warning,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Votre passeport est signé numériquement.\n'
            'Scannez ce code avec votre téléphone ou présentez-le au '
            'comptoir pour récupérer votre document.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: QrImageView(
            data: passeport.qrPayload,
            version: QrVersions.auto,
            size: 160,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'ID: $idCourt',
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _reinitialiser,
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
          label: const Text('Nouvelle transaction'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Colors.white24),
          ),
        ),
      ],
    );
  }

  Widget _peseeView() => Column(key: const ValueKey('pesee'), mainAxisSize: MainAxisSize.min, children: [
        Text('${(_poidsVerrouilleG ?? _poidsG).toStringAsFixed(2)} g', style: TextStyle(color: _poidsStabilise ? SirexeTheme.success : Colors.white, fontSize: 76, fontWeight: FontWeight.w800, letterSpacing: -2, shadows: [Shadow(color: SirexeTheme.success.withOpacity(0.35), blurRadius: 26)])),
        const SizedBox(height: 8),
        _pill(_poidsStabilise ? Icons.lock_rounded : Icons.sync_rounded, _poidsStabilise ? 'POIDS VERROUILLE' : 'LECTURE EN DIRECT', _poidsStabilise ? SirexeTheme.success : SirexeTheme.warning),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: LinearProgressIndicator(
            value: _poidsStabilise ? 1 : null,
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(_poidsStabilise ? SirexeTheme.success : SirexeTheme.warning),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 18),
        Text(_poidsStabilise ? 'Pesee stabilisee. Generation du passeport...' : 'Attendez la stabilisation automatique de la balance.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 14)),
        if (_operateur != null) ...[const SizedBox(height: 25), _infoCard('Exploitant', _operateur!.nom, 'Permis ${_operateur!.permisId}')],
      ]);

  Widget _ticketView() {
    final p = _passeport;
    if (p == null) return Column(key: const ValueKey('ticket-loading'), mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(), const SizedBox(height: 20), const Text('Signature du passeport en cours...', style: TextStyle(color: Colors.white60))]);
    return Column(key: const ValueKey('ticket'), mainAxisSize: MainAxisSize.min, children: [
      Container(width: 330, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFFFFFCF4), borderRadius: BorderRadius.circular(5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 18)]), child: Column(children: [
        const Text('GEODEX', style: TextStyle(color: Color(0xFF12221D), fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
        const Text('PASSEPORT MINERAL SIGNE', style: TextStyle(color: Color(0xFF52605B), fontSize: 9, letterSpacing: 1)),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFCED4CF))),
        QrImageView(data: p.qrPayload, version: QrVersions.auto, size: 142, backgroundColor: const Color(0xFFFFFCF4)),
        const SizedBox(height: 10),
        _ticketLine('Exploitant', p.operateurNom), _ticketLine('Permis', p.permisNumero), _ticketLine('Poids net', '${p.poidsNetG.toStringAsFixed(2)} g'), _ticketLine('Borne', 'TONGON-01'), _ticketLine('Lieu', '9.167, -6.483'), _ticketLine('Date', _dateCourte(DateTime.now())),
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: Color(0xFFCED4CF))),
        Text(
          'ID ${(p.id.length >= 8 ? p.id.substring(0, 8) : p.id).toUpperCase()}  •  VERIFIABLE',
          style: const TextStyle(color: Color(0xFF52605B), fontSize: 8, fontWeight: FontWeight.w700),
        ),
        if (p.horsZone) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off, size: 14, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  '⚠️ Hors zone — ${p.distanceZoneM}m',
                  style: const TextStyle(color: Colors.orange, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ])),
      const SizedBox(height: 18),
      _pill(_ticketImprime ? Icons.check_circle_rounded : Icons.print_rounded, _ticketImprime ? 'TICKET REMIS - MERCI' : _impressionEnCours ? 'IMPRESSION EN COURS...' : 'PREPARATION DU TICKET', _ticketImprime ? SirexeTheme.success : SirexeTheme.warning),
    ]);
  }

  Widget _emptyState(String key, IconData icon, String title, String text, Color color) => Column(key: ValueKey(key), mainAxisSize: MainAxisSize.min, children: [Container(width: 102, height: 102, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.11), border: Border.all(color: color.withOpacity(0.35))), child: Icon(icon, color: color, size: 49)), const SizedBox(height: 24), Text(title, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: 1)), const SizedBox(height: 10), Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.4))]);

  Widget _demoPanel() => Column(children: [
        TextButton.icon(onPressed: () => setState(() => _modeDemoVisible = !_modeDemoVisible), icon: Icon(_modeDemoVisible ? Icons.keyboard_arrow_up : Icons.tune_rounded, size: 16), label: Text(_modeDemoVisible ? 'MASQUER LE MODE DEMO' : 'OUVRIR LE MODE DEMO', style: const TextStyle(fontSize: 10, letterSpacing: 1))),
        if (_modeDemoVisible) Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.08))), child: Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
          _demoButton('Badge KONE', 'CARD-A1B2C3', SirexeTheme.success), _demoButton('Badge quota', 'CARD-D4E5F6', SirexeTheme.warning), _demoButton('Badge invalide', 'CARD-ZZZZZZ', Colors.redAccent),
          if (_etat == EtatBorne.attentePesee) OutlinedButton.icon(onPressed: _simulerStabilisation, icon: const Icon(Icons.scale_rounded, size: 16), label: const Text('Stabiliser la balance')),
        ])),
      ]);

  Widget _demoButton(String label, String uid, Color color) => OutlinedButton.icon(onPressed: _etat == EtatBorne.attenteBadge ? () => _demarrerCycle(uid, demo: true) : null, icon: Icon(Icons.credit_card_rounded, color: color, size: 16), label: Text(label), style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: BorderSide(color: color.withOpacity(0.5))));
  Widget _materielLigne(IconData icon, String label, bool ok) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Icon(icon, size: 16, color: ok ? SirexeTheme.success : Colors.redAccent), const SizedBox(width: 9), Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))), Text(ok ? 'CONNECTE' : 'ERREUR', style: TextStyle(color: ok ? SirexeTheme.success : Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w700))]));
  Widget _steps() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(4, (i) { final active = _etat.index == i; final done = _etat.index > i; final color = done ? SirexeTheme.success : active ? Colors.white : Colors.white24; return Column(children: [Icon([Icons.contactless_rounded, Icons.verified_user_rounded, Icons.scale_rounded, Icons.print_rounded][i], color: color, size: 18), const SizedBox(height: 4), Text(['BADGE', 'ID', 'POIDS', 'TICKET'][i], style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700))]); }));
  Widget _pill(IconData icon, String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 6), Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6))]));
  Widget _eyebrow(String value) => Text(value, style: TextStyle(color: Colors.white.withOpacity(0.42), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.3));
  Widget _infoCard(String label, String title, String sub) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withOpacity(0.045), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.08))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_eyebrow(label), const SizedBox(height: 5), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12))]));
  Widget _ticketLine(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Color(0xFF52605B), fontSize: 10)), Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFF12221D), fontSize: 10, fontWeight: FontWeight.w700)))]));
  String _dateCourte(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  Color get _etatColor => _etat == EtatBorne.erreur ? Colors.redAccent : _etat == EtatBorne.impression ? SirexeTheme.warning : SirexeTheme.success;
  IconData get _etatIcon => _etat == EtatBorne.erreur ? Icons.error_outline_rounded : _etat == EtatBorne.impression ? Icons.verified_rounded : _etat == EtatBorne.attentePesee ? Icons.scale_rounded : Icons.contactless_rounded;
  String get _etatLabel => switch (_etat) { EtatBorne.attenteBadge => 'PRET A VOUS IDENTIFIER', EtatBorne.identification => 'IDENTIFICATION', EtatBorne.attentePesee => _poidsStabilise ? 'POIDS VERROUILLE' : 'PESEE EN COURS', EtatBorne.impression => _ticketImprime ? 'TICKET REMIS' : 'PASSEPORT SIGNE', EtatBorne.erreur => 'INTERVENTION REQUISE' };
  String get _etatHint => switch (_etat) { EtatBorne.attenteBadge => 'Presentez votre carte RFID.', EtatBorne.identification => 'Controle de l identite et du quota.', EtatBorne.attentePesee => 'Le poids est lu automatiquement par la balance.', EtatBorne.impression => 'Votre ticket securise est en cours de remise.', EtatBorne.erreur => 'Retour automatique a l ecran d accueil.' };
}
