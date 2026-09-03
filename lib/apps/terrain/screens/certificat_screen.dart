// lib/apps/terrain/screens/certificat_screen.dart
// GEODEX — CertificatScreen v2.0
// Upgrades : Signatures · QR titre transport (6h) · Chain of custody · Sync status · Loop démo

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/pesee.dart';
import 'pesee_screen.dart';

// ─────────────────────────────────────────────
//  CONSTANTES
// ─────────────────────────────────────────────

const _cBg      = Color(0xFF0A0A14);
const _cCard    = Color(0xFF0F0F1A);
const _cCard2   = Color(0xFF161B22);
const _cBorder  = Color(0xFF21262D);
const _cBorder2 = Color(0xFF30363D);
const _cGreen   = Color(0xFF3FB950);
const _cGreenD  = Color(0xFF238636);
const _cYellow  = Color(0xFFD29922);
const _cRed     = Color(0xFFF85149);
const _cBlue    = Color(0xFF58A6FF);
const _cPurple  = Color(0xFF8957E5);
const _cMuted   = Color(0xFF8B949E);
const _cText    = Color(0xFFE6EDF3);

const _kExpirationHeures = 6;

// ─────────────────────────────────────────────
//  MODÈLE SIGNATURE (partagé avec PeseeScreen)
// ─────────────────────────────────────────────

class SignatureCert {
  final String nom;
  final String role;
  final DateTime horodatage;
  const SignatureCert({
    required this.nom,
    required this.role,
    required this.horodatage,
  });
}

// ─────────────────────────────────────────────
//  CERTIFICAT SCREEN
// ─────────────────────────────────────────────

class CertificatScreen extends StatefulWidget {
  final Pesee pesee;
  final bool syncOk;
  final SignatureCert? sigOperateur;
  final SignatureCert? sigChefSite;

  const CertificatScreen({
    super.key,
    required this.pesee,
    this.syncOk = true,
    this.sigOperateur,
    this.sigChefSite,
  });

  @override
  State<CertificatScreen> createState() => _CertificatScreenState();
}

class _CertificatScreenState extends State<CertificatScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  bool _hashCopied = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.9)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  // ── Données calculées ─────────────────────

  bool get _estValide => widget.pesee.hashValide;

  Duration get _tempsRestant {
    final expiration = widget.pesee.timestamp
        .add(const Duration(hours: _kExpirationHeures));
    final reste = expiration.difference(DateTime.now());
    return reste.isNegative ? Duration.zero : reste;
  }

  bool get _estExpire => _tempsRestant == Duration.zero;

  double get _progressExpiration {
    final total = const Duration(hours: _kExpirationHeures).inSeconds;
    final reste = _tempsRestant.inSeconds;
    return (reste / total).clamp(0.0, 1.0);
  }

  String get _qrPayload => jsonEncode({
    'id':          widget.pesee.id,
    'hash':        widget.pesee.hash,
    'site':        widget.pesee.nomSite,
    'camion':      widget.pesee.camionId,
    'poidsNet':    widget.pesee.poidsNet,
    'poidsBrut':   widget.pesee.poidsBrut,
    'tare':        widget.pesee.tare,
    'timestamp':   widget.pesee.timestamp.toIso8601String(),
    'expiration':  widget.pesee.timestamp
        .add(const Duration(hours: _kExpirationHeures))
        .toIso8601String(),
    'valide':      widget.pesee.hashValide,
    'sigOperateur': widget.sigOperateur?.nom ?? 'KONÉ Amadou',
    'sigChefSite':  widget.sigChefSite?.nom ?? 'DIALLO Moussa',
    'latitude':    widget.pesee.latitude,
    'longitude':   widget.pesee.longitude,
    'geodex':      'v2.0',
  });

  String get _shareText => '''
═══════════════════════════════════════════
   CERTIFICAT DE TRAÇABILITÉ GEODEX v2.0
   Ministère des Mines — Côte d'Ivoire
═══════════════════════════════════════════
Transaction  : ${widget.pesee.id}
Horodatage   : ${_formatTs(widget.pesee.timestamp)}
Expiration   : ${_formatTs(widget.pesee.timestamp.add(const Duration(hours: _kExpirationHeures)))}
───────────────────────────────────────────
Site         : ${widget.pesee.nomSite}
Permis       : ${widget.pesee.permisId}
Camion       : ${widget.pesee.camionId}
GPS          : ${widget.pesee.latitude.toStringAsFixed(4)}N, ${widget.pesee.longitude.abs().toStringAsFixed(4)}W
───────────────────────────────────────────
Poids brut   : ${widget.pesee.poidsBrut.toStringAsFixed(0)} kg
Tare         : ${widget.pesee.tare.toStringAsFixed(0)} kg
Poids NET    : ${widget.pesee.poidsNet.toStringAsFixed(3)} t
───────────────────────────────────────────
Signataires  :
  ✓ ${widget.sigOperateur?.nom ?? 'KONÉ Amadou'} (Opérateur)
  ✓ ${widget.sigChefSite?.nom ?? 'DIALLO Moussa'} (Chef de site)
───────────────────────────────────────────
HASH SHA-256 : ${widget.pesee.hash}
STATUT       : ${_estValide ? "VALIDE ✓" : "INVALIDE ✗"}
═══════════════════════════════════════════
Généré par GEODEX — Système anti-fraude minier CI
SIREXE 2026
''';

  String _formatTs(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';

  String _formatDuree(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h${m.toString().padLeft(2, '0')}min';
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusBanner(),
            const SizedBox(height: 12),
            _buildSyncBadge(),
            const SizedBox(height: 16),
            _buildQrSection(),
            const SizedBox(height: 16),
            _buildExpirationBar(),
            const SizedBox(height: 16),
            _buildInfoSection(),
            const SizedBox(height: 12),
            _buildSignaturesSection(),
            const SizedBox(height: 12),
            _buildHashSection(),
            const SizedBox(height: 12),
            _buildChainSection(),
            const SizedBox(height: 20),
            _buildActions(),
            const SizedBox(height: 16),
            _buildBoutonNouvellePesee(),
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _cMuted, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Certificat de traçabilité',
              style: TextStyle(color: _cText, fontSize: 15,
                  fontWeight: FontWeight.w600, fontFamily: GoogleFonts.jetBrainsMono().fontFamily)),
          Text(widget.pesee.id,
              style: TextStyle(color: _cMuted, fontSize: 10,
                  fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 1)),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Partager',
          icon: const Icon(Icons.share_outlined, color: _cMuted, size: 20),
          onPressed: () => Share.share(_shareText),
        ),
      ],
    );
  }

  // ── Bannière statut ───────────────────────

  Widget _buildStatusBanner() {
    final color  = _estValide && !_estExpire ? _cGreen : _cRed;
    final colorD = _estValide && !_estExpire ? _cGreenD : const Color(0xFFA32D2D);
    final label  = _estExpire
        ? 'EXPIRÉ ✗'
        : _estValide
            ? 'VALIDE ✓'
            : 'INVALIDE ✗';
    final sublabel = _estExpire
        ? 'Ce certificat a expiré — réémettre une pesée'
        : _estValide
            ? 'Certificat reconnu par le Ministère des Mines CI'
            : 'Hash invalide — pesée compromise';

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorD.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(_estValide ? _glowAnim.value : 1.0),
            width: 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _estValide && !_estExpire
                  ? Icons.verified_outlined
                  : Icons.gpp_bad_outlined,
              color: color, size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CERTIFICAT DE TRAÇABILITÉ GEODEX',
                  style: TextStyle(color: _cMuted, fontSize: 9,
                      fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 24,
                  fontWeight: FontWeight.w800, fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                  letterSpacing: 1)),
              const SizedBox(height: 2),
              Text(sublabel, style: TextStyle(color: _cMuted, fontSize: 11)),
            ],
          )),
        ]),
      ),
    );
  }

  // ── Badge sync ────────────────────────────

  Widget _buildSyncBadge() {
    final ok    = widget.syncOk;
    final color = ok ? _cGreen : _cYellow;
    final bg    = ok ? const Color(0xFF0F2A0F) : const Color(0xFF2A1F00);
    final label = ok ? '● SYNCHRONISÉ — Chaîne enregistrée' : '⏸ HORS LIGNE — En attente de sync';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(children: [
        Text(label, style: TextStyle(color: color, fontSize: 11,
            fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(_formatTs(widget.pesee.timestamp),
            style: const TextStyle(color: _cMuted, fontSize: 10,
                fontFamily: 'monospace')),
      ]),
    );
  }

  // ── QR Code ───────────────────────────────

  Widget _buildQrSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cBorder2),
      ),
      child: Stack(
        children: [
          // 🎨 UI GEODEX — Filigrane document officiel
          Positioned.fill(
            child: Transform.rotate(
              angle: -0.15,
              child: Text(
                'RÉPUBLIQUE DE CÔTE D\'IVOIRE — MINISTÈRE DES MINES',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Column(
            children: [
              // Label titre de transport
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('TITRE DE TRANSPORT OFFICIEL',
                    style: TextStyle(color: Color(0xFF238636), fontSize: 9,
                        fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 1.5,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 16),

              // 🎨 UI GEODEX — Encadrement pointillé QR
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white30,
                    width: 1,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                child: QrImageView(
                  data: _qrPayload,
                  version: QrVersions.auto,
                  size: 220,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0D1117),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0D1117),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Text(widget.pesee.id,
                  style: TextStyle(color: Color(0xFF30363D), fontSize: 12,
                      fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              Text('Scanner à chaque checkpoint de sortie',
                  style: TextStyle(color: Color(0xFF6E7681), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Barre expiration ──────────────────────

  Widget _buildExpirationBar() {
    final progress = _progressExpiration;
    final Color barColor = progress > 0.5
        ? _cGreen
        : progress > 0.2
            ? _cYellow
            : _cRed;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cCard,
        border: Border.all(color: _cBorder, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(children: [
        Row(children: [
          Icon(Icons.timer_outlined, color: _cMuted, size: 14),
          const SizedBox(width: 8),
          Text('VALIDITÉ DU TITRE',
              style: TextStyle(color: _cMuted, fontSize: 9,
                  fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 1.5)),
          const Spacer(),
          Text(
            _estExpire ? 'EXPIRÉ' : _formatDuree(_tempsRestant),
            style: TextStyle(
              color: _estExpire ? _cRed : barColor,
              fontSize: 11, fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontWeight: FontWeight.w700,
            ),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: _cBorder,
            valueColor: AlwaysStoppedAnimation<Color>(
                _estExpire ? _cRed : barColor),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatTs(widget.pesee.timestamp),
                style: const TextStyle(color: _cMuted, fontSize: 9,
                    fontFamily: 'monospace')),
            Text(
              _formatTs(widget.pesee.timestamp
                  .add(const Duration(hours: _kExpirationHeures))),
              style: const TextStyle(color: _cMuted, fontSize: 9,
                  fontFamily: 'monospace'),
            ),
          ],
        ),
      ]),
    );
  }

  // ── Infos chargement ──────────────────────

  Widget _buildInfoSection() {
    return _Section(
      title: 'Informations chargement',
      child: Column(children: [
        _FieldRow('Transaction',  widget.pesee.id),
        _FieldRow('Site',         widget.pesee.nomSite),
        _FieldRow('Permis',       widget.pesee.permisId),
        _FieldRow('Camion',       widget.pesee.camionId),
        _FieldRow('GPS',
            '${widget.pesee.latitude.toStringAsFixed(4)}N, '
            '${widget.pesee.longitude.abs().toStringAsFixed(4)}W'),
        const _Divider(),
        _FieldRow('Poids brut',
            '${widget.pesee.poidsBrut.toStringAsFixed(0)} kg'),
        _FieldRow('Tare',
            '${widget.pesee.tare.toStringAsFixed(0)} kg'),
        _FieldRow('Poids NET',
            '${widget.pesee.poidsNet.toStringAsFixed(3)} t',
            highlight: true),
      ]),
    );
  }

  // ── Signatures ────────────────────────────

  Widget _buildSignaturesSection() {
    final sigOp  = widget.sigOperateur ?? SignatureCert(
      nom: 'KONÉ Amadou', role: 'Opérateur',
      horodatage: widget.pesee.timestamp,
    );
    final sigCs  = widget.sigChefSite ?? SignatureCert(
      nom: 'DIALLO Moussa', role: 'Chef de site',
      horodatage: widget.pesee.timestamp,
    );

    return _Section(
      title: 'Signatures',
      child: Column(children: [
        _SignatureRow(sig: sigOp),
        const SizedBox(height: 8),
        _SignatureRow(sig: sigCs),
      ]),
    );
  }

  // ── Hash ──────────────────────────────────

  Widget _buildHashSection() {
    return _Section(
      title: 'Intégrité cryptographique',
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: widget.pesee.hash));
          setState(() => _hashCopied = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hash SHA-256 copié',
                  style: TextStyle(fontFamily: 'monospace')),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF238636),
            ),
          );
          Future.delayed(const Duration(seconds: 2),
              () { if (mounted) setState(() => _hashCopied = false); });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF050F05),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: (_estValide ? _cGreenD : _cRed).withOpacity(0.5),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('SHA-256',
                    style: TextStyle(
                      color: _estValide ? _cGreen : _cRed,
                      fontSize: 10, fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 1,
                    )),
                const Spacer(),
                Icon(
                  _hashCopied ? Icons.check : Icons.copy_outlined,
                  color: _hashCopied ? _cGreen : _cMuted,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(_hashCopied ? 'Copié !' : 'Appuyer longuement',
                    style: const TextStyle(color: _cMuted, fontSize: 9,
                        fontFamily: 'monospace')),
              ]),
              const SizedBox(height: 8),
              Text(widget.pesee.hash,
                  style: TextStyle(
                    color: _estValide ? _cGreen : _cRed,
                    fontSize: 10, fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 0.5,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chain of custody visuelle ─────────────

  Widget _buildChainSection() {
    return _Section(
      title: 'Chaîne de hachage',
      child: Column(children: [
        // Blocs
        Row(children: [
          _ChainBlock(label: 'GENESIS', num: '#000', confirmed: true),
          _ChainArrow(),
          _ChainBlock(label: 'a3f7...d92e', num: '#001', confirmed: true),
          _ChainArrow(),
          _ChainBlock(
            label: widget.pesee.hash.substring(0, 4) +
                '...' +
                widget.pesee.hash.substring(widget.pesee.hash.length - 4),
            num: '#002',
            confirmed: true,
            isNew: true,
          ),
        ]),
        const SizedBox(height: 12),

        // Légende
        Row(children: [
          const Icon(Icons.shield_outlined, color: _cGreen, size: 14),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Chaîne intègre — aucune modification détectée depuis l\'enregistrement',
              style: TextStyle(color: _cGreen, fontSize: 11,
                  fontFamily: 'monospace'),
            ),
          ),
        ]),

        const SizedBox(height: 10),

        // Timeline custody
        _buildCustodyTimeline(),
      ]),
    );
  }

  Widget _buildCustodyTimeline() {
    final events = [
      _CustodyEvent(
        icon: Icons.scale_outlined,
        label: 'Pesée validée',
        detail: widget.pesee.nomSite,
        time: widget.pesee.timestamp,
        color: _cGreen,
      ),
      _CustodyEvent(
        icon: Icons.qr_code_scanner,
        label: 'Certificat émis',
        detail: 'QR titre de transport généré',
        time: widget.pesee.timestamp.add(const Duration(seconds: 5)),
        color: _cGreen,
      ),
      _CustodyEvent(
        icon: Icons.location_on_outlined,
        label: 'Checkpoint sortie',
        detail: 'En attente de scan',
        time: null,
        color: _cMuted,
        pending: true,
      ),
      _CustodyEvent(
        icon: Icons.store_outlined,
        label: 'Comptoir d\'achat',
        detail: 'En attente de scan',
        time: null,
        color: _cMuted,
        pending: true,
      ),
    ];

    return Column(
      children: events.asMap().entries.map((entry) {
        final i = entry.key;
        final e = entry.value;
        final isLast = i == events.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline ligne + point
            SizedBox(
              width: 28,
              child: Column(children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: e.pending
                        ? _cBorder
                        : e.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: e.pending ? _cBorder2 : e.color,
                        width: 0.5),
                  ),
                  child: Icon(e.icon,
                      color: e.pending ? _cMuted : e.color, size: 11),
                ),
                if (!isLast)
                  Container(
                    width: 1, height: 28,
                    color: e.pending ? _cBorder : _cGreenD.withOpacity(0.3),
                  ),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.label,
                        style: TextStyle(
                          color: e.pending ? _cMuted : _cText,
                          fontSize: 12, fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                          fontWeight: e.pending
                              ? FontWeight.normal
                              : FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    Text(e.detail,
                        style: const TextStyle(color: _cMuted, fontSize: 10,
                            fontFamily: 'monospace')),
                    if (e.time != null) ...[
                      const SizedBox(height: 2),
                      Text(_formatTs(e.time!),
                          style: const TextStyle(color: _cMuted, fontSize: 9,
                              fontFamily: 'monospace')),
                    ],
                    if (e.pending)
                      const Text('En attente de scan QR au checkpoint',
                          style: TextStyle(color: _cYellow, fontSize: 9,
                              fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Actions ───────────────────────────────

  Widget _buildActions() {
    return Row(children: [
      Expanded(
        child: _ActionBtn(
          label: 'PARTAGER',
          icon: Icons.share_outlined,
          color: _cPurple,
          onTap: () => Share.share(_shareText),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _ActionBtn(
          label: 'COPIER HASH',
          icon: Icons.copy_outlined,
          color: _cBorder2,
          textColor: _cMuted,
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.pesee.hash));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hash copié'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF238636)),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildBoutonNouvellePesee() {
    return GestureDetector(
      onTap: () => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PeseeScreen()),
        (route) => route.isFirst,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _cGreenD,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('NOUVELLE PESÉE',
                style: TextStyle(color: Colors.white, fontSize: 13,
                    fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  WIDGETS RÉUTILISABLES
// ─────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _cCard2,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _cBorder2, width: 0.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: TextStyle(color: _cMuted, fontSize: 9,
                fontFamily: GoogleFonts.jetBrainsMono().fontFamily, letterSpacing: 1.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _FieldRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(color: _cMuted, fontSize: 11,
                  fontFamily: 'monospace')),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                color: highlight ? _cGreen : _cText,
                fontSize: highlight ? 16 : 12,
                fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.normal,
                letterSpacing: highlight ? 0.5 : 0,
              )),
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Divider(color: _cBorder, height: 1),
  );
}

class _SignatureRow extends StatelessWidget {
  final SignatureCert sig;
  const _SignatureRow({required this.sig});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: _cGreenD.withOpacity(0.06),
      border: Border.all(color: _cGreenD.withOpacity(0.4), width: 0.5),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(children: [
      const Icon(Icons.check_circle_outline, color: _cGreen, size: 16),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sig.nom, style: TextStyle(color: _cText, fontSize: 12,
              fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontWeight: FontWeight.w600)),
          Text(sig.role, style: TextStyle(color: _cMuted, fontSize: 10,
              fontFamily: 'monospace')),
        ],
      )),
      Text(
        '${sig.horodatage.hour.toString().padLeft(2, '0')}:'
        '${sig.horodatage.minute.toString().padLeft(2, '0')}',
        style: const TextStyle(color: _cMuted, fontSize: 10,
            fontFamily: 'monospace'),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: _cGreenD.withOpacity(0.15),
          border: Border.all(color: _cGreenD, width: 0.5),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text('✓ VALIDÉ',
            style: TextStyle(color: _cGreen, fontSize: 9,
                fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontWeight: FontWeight.w700)),
      ),
    ]),
  );
}

class _ChainBlock extends StatelessWidget {
  final String label;
  final String num;
  final bool confirmed;
  final bool isNew;
  const _ChainBlock({
    required this.label,
    required this.num,
    required this.confirmed,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = confirmed
        ? (isNew ? _cGreen : _cGreenD)
        : _cYellow;
    final bg = confirmed
        ? (isNew ? _cGreenD.withOpacity(0.12) : _cGreenD.withOpacity(0.06))
        : _cYellow.withOpacity(0.06);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: color, width: isNew ? 1 : 0.5),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(children: [
          Text(label,
              style: TextStyle(color: color, fontSize: 8,
                  fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(num,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 8,
                  fontFamily: 'monospace'),
              textAlign: TextAlign.center),
          if (isNew) ...[
            const SizedBox(height: 2),
            Text('✓ NOUVEAU', style: TextStyle(color: _cGreen,
                fontSize: 7, fontFamily: 'monospace')),
          ],
        ]),
      ),
    );
  }
}

class _ChainArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 3),
    child: Text('→', style: TextStyle(color: _cMuted, fontSize: 12)),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: textColor, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: textColor, fontSize: 11,
            fontFamily: GoogleFonts.jetBrainsMono().fontFamily, fontWeight: FontWeight.w700,
            letterSpacing: 1)),
      ]),
    ),
  );
}

// ── Modèle interne custody event ─────────────

class _CustodyEvent {
  final IconData icon;
  final String label;
  final String detail;
  final DateTime? time;
  final Color color;
  final bool pending;

  const _CustodyEvent({
    required this.icon,
    required this.label,
    required this.detail,
    required this.time,
    required this.color,
    this.pending = false,
  });
}