import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:geodex/core/theme.dart';
import 'package:geodex/core/config/api_config.dart';

class ResultatQR {
  final bool valide;
  final String? id;
  final String? operateurNom;
  final String? permisId;
  final double? poidsNetG;
  final DateTime? expiration;
  final String? qrPayload;
  final String? motifRefus;
  final StatutQR statut;

  const ResultatQR({
    required this.valide,
    required this.statut,
    this.id,
    this.operateurNom,
    this.permisId,
    this.poidsNetG,
    this.expiration,
    this.qrPayload,
    this.motifRefus,
  });
}

enum StatutQR { valide, expire, signatureInvalide, formatInvalide, indisponible }

class ComptoirScanScreen extends StatefulWidget {
  const ComptoirScanScreen({super.key});

  @override
  State<ComptoirScanScreen> createState() => _ComptoirScanScreenState();
}

class _ComptoirScanScreenState extends State<ComptoirScanScreen> {
  final TextEditingController _ctrl = TextEditingController();
  ResultatQR? _resultat;
  bool _scanning = false;

  Future<ResultatQR> _validerPasseport(String raw) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/pesees/passports/verify'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'qrPayload': raw}),
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final passeport = data['passeport'] as Map<String, dynamic>?;
      final expirationMs = passeport?['expiration'] as num?;
      final expiration = expirationMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expirationMs.toInt());

      if (data['valide'] == true && passeport != null && expiration != null) {
        return ResultatQR(
          valide: true,
          statut: StatutQR.valide,
          id: passeport['id'] as String?,
          operateurNom: passeport['operateurNom'] as String?,
          permisId: passeport['permisId'] as String?,
          poidsNetG: (passeport['poidsNetG'] as num?)?.toDouble(),
          expiration: expiration,
          qrPayload: raw,
        );
      }
      return ResultatQR(
        valide: false,
        statut: data['code'] == 'PASSEPORT_EXPIRE'
            ? StatutQR.expire
            : data['code'] == 'SIGNATURE_INVALIDE'
                ? StatutQR.signatureInvalide
                : StatutQR.formatInvalide,
        motifRefus: data['motifRefus'] as String? ?? 'Passeport refuse',
      );
    } catch (_) {
      return const ResultatQR(
        valide: false,
        statut: StatutQR.indisponible,
        motifRefus: 'Verification indisponible. Transaction refusee.',
      );
    }
  }

  void _scanner() {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) return;
    setState(() {
      _scanning = true;
      _resultat = null;
    });

    _validerPasseport(raw).then((resultat) {
      if (!mounted) return;
      setState(() {
        _resultat = resultat;
        _scanning = false;
      });
    });
  }

  Future<void> _telechargerPDF(ResultatQR passeport) async {
    final qrPayload = passeport.qrPayload;
    final id = passeport.id;
    if (!passeport.valide || qrPayload == null || id == null) return;

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: pw.Font.helvetica()),
    );
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('GEODEX', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
              pw.SizedBox(height: 4),
              pw.Text('PASSEPORT MINERAL DE SUBSTITUTION', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              _pdfRow('Exploitant', passeport.operateurNom ?? 'Non renseigne'),
              _pdfRow('Permis', passeport.permisId ?? 'Non renseigne'),
              _pdfRow('Poids net', '${(passeport.poidsNetG ?? 0).toStringAsFixed(2)} g'),
              _pdfRow('Comptoir', 'GEODEX'),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.BarcodeWidget(data: qrPayload, width: 120, height: 120, barcode: pw.Barcode.qrCode()),
              pw.SizedBox(height: 8),
              pw.Text('ID: $id', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800)),
              pw.Text("Généré depuis le comptoir suite à une panne d'impression.", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 6, color: PdfColors.red)),
            ],
          ),
        ),
      ),
    );

    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final idCourt = id.length >= 8 ? id.substring(0, 8) : id;
    html.AnchorElement(href: url)
      ..setAttribute('download', 'Passeport_$idCourt.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  pw.Widget _pdfRow(String label, String value) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      );

  void _reinitialiser() {
    setState(() {
      _ctrl.clear();
      _resultat = null;
    });
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _ctrl.dispose();
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
              const SizedBox(height: 6),
              Text(
                "COMPTOIR D'ACHAT — VERIFICATION PASSEPORT",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 48),

              Container(
                width: 560,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: SirexeTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: _resultat == null
                    ? _buildSaisie()
                    : _buildResultat(),
              ),

              const SizedBox(height: 24),

              if (_resultat == null)
                Text(
                  "La signature est verifiee par le serveur GEODEX avant validation.",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.15), fontSize: 10),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaisie() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.qr_code_scanner,
            size: 56, color: Colors.white.withOpacity(0.2)),
        const SizedBox(height: 24),
        const Text(
          "SCANNER LE PASSEPORT MINERAL",
          style: TextStyle(
            color: Colors.white54,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        TextField(
          controller: _ctrl,
          maxLines: 4,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Collez le payload QR ici...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: SirexeTheme.success.withOpacity(0.5)),
            ),
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _scanning ? null : _scanner,
            icon: _scanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.verified_user, size: 18),
            label: Text(_scanning ? 'Verification...' : 'Verifier le passeport'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SirexeTheme.success,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultat() {
    final r = _resultat!;
    final couleur = r.valide ? SirexeTheme.success : Colors.redAccent;
    final icone = r.valide ? Icons.check_circle : Icons.cancel;
    final titre = r.valide ? 'PASSEPORT VALIDE' : 'PASSEPORT REFUSE';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 64, color: couleur),
        const SizedBox(height: 16),
        Text(
          titre,
          style: TextStyle(
            color: couleur,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: 24),
        const Divider(color: Colors.white10),
        const SizedBox(height: 16),

        if (r.valide) ...[
          _ligne('Operateur', r.operateurNom ?? '—'),
          _ligne('Permis', r.permisId ?? '—'),
          _ligne('Poids net',
              '${(r.poidsNetG ?? 0).toStringAsFixed(2)} g'),
          _ligne('Expire le', _formatDate(r.expiration!)),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
            ),
            child: Text(
              r.motifRefus ?? 'Motif inconnu',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.redAccent, fontSize: 14, height: 1.5),
            ),
          ),
          if (r.operateurNom != null) ...[
            const SizedBox(height: 12),
            _ligne('Operateur', r.operateurNom!),
          ],
        ],

        const SizedBox(height: 24),
        const Divider(color: Colors.white10),
        const SizedBox(height: 16),

        Row(
          children: [
            if (r.valide)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _reinitialiser,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Valider transaction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SirexeTheme.success,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            if (r.valide) const SizedBox(width: 12),
            if (r.valide)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _telechargerPDF(r),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Télécharger PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SirexeTheme.success,
                    side: BorderSide(color: SirexeTheme.success.withOpacity(0.45)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            if (r.valide) const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reinitialiser,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Nouveau scan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: BorderSide(color: Colors.white.withOpacity(0.15)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ligne(String label, String valeur) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 13)),
            Text(valeur,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}
