import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme.dart';
import '../../../core/config/api_config.dart';

class VerificationChainScreen extends StatefulWidget {
  const VerificationChainScreen({super.key});

  @override
  State<VerificationChainScreen> createState() => _VerificationChainScreenState();
}

class _VerificationChainScreenState extends State<VerificationChainScreen> {
  List<dynamic> _blocs = [];
  Map<String, dynamic>? _rapport;
  bool _loading = false;
  bool? _integre;
  String _message = '';
  Map<String, dynamic>? _premierBlocCorrompu;

  Future<void> _verifier() async {
    setState(() { _loading = true; _blocs = []; _rapport = null; });
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/pesees/verify-chain'))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      setState(() {
        _integre            = data['integre'] as bool?;
        _message            = data['message'] ?? '';
        _blocs              = data['blocs'] ?? [];
        _rapport            = data['rapport'];
        _premierBlocCorrompu = data['premierBlocCorrompu'];
        _loading            = false;
      });
    } catch (e) {
      setState(() { _loading = false; _message = 'Erreur : $e'; });
    }
  }

  Future<void> _falsifier() async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/pesees/dev/falsifier'),
    );
    final data = jsonDecode(res.body);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Falsification effectuée'),
          backgroundColor: SirexeTheme.danger,
        ),
      );
      await _verifier();
    }
  }

  Future<void> _reset() async {
    await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/pesees/dev/reset-chaine'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chaîne réinitialisée')),
      );
      setState(() {
        _blocs = []; _rapport = null;
        _integre = null; _message = '';
        _premierBlocCorrompu = null;
      });
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}h'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SirexeTheme.background,
      body: Row(children: [

        SizedBox(
          width: 460,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: SirexeTheme.surface1,
                border: Border(
                  bottom: BorderSide(color: SirexeTheme.border, width: 0.5),
                  right:  BorderSide(color: SirexeTheme.border, width: 0.5),
                ),
              ),
              child: Row(children: [
                Icon(Icons.link, size: 16, color: SirexeTheme.accentBlue),
                const SizedBox(width: 8),
                Text('REGISTRE — ${_blocs.length} blocs',
                    style: TextStyle(
                      color: SirexeTheme.accentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    )),
                const Spacer(),
                if (_rapport != null) ...[
                  _badge('${_rapport!['integres']} ✓', SirexeTheme.success),
                  const SizedBox(width: 6),
                  _badge('${_rapport!['corrompus']} ✗', SirexeTheme.danger),
                ],
              ]),
            ),

            Expanded(
              child: _blocs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link,
                              size: 40,
                              color: SirexeTheme.textSecondary.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('Lancez la vérification',
                              style: TextStyle(
                                  color: SirexeTheme.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _blocs.length,
                      itemBuilder: (_, i) {
                        final b = _blocs[i];
                        final ok = b['integre'] as bool;
                        final couleur = ok ? SirexeTheme.success : SirexeTheme.danger;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: SirexeTheme.surface1,
                            borderRadius: BorderRadius.circular(4),
                            border: Border(
                              left: BorderSide(color: couleur, width: 4),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text('#${b['index'].toString().padLeft(3, '0')}',
                                      style: TextStyle(
                                        color: couleur,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      )),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      b['operateurNom'] ?? b['permisId'] ?? '—',
                                      style: const TextStyle(
                                        color: SirexeTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    ok ? Icons.verified : Icons.gpp_bad,
                                    size: 16,
                                    color: couleur,
                                  ),
                                ]),
                                const SizedBox(height: 6),
                                Row(children: [
                                  Icon(Icons.scale_outlined,
                                      size: 11,
                                      color: SirexeTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(b['poidsNetG'] as num).toStringAsFixed(0)} g',
                                    style: TextStyle(
                                      color: SirexeTheme.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.access_time,
                                      size: 11,
                                      color: SirexeTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(b['timestamp']?.toString()),
                                    style: TextStyle(
                                      color: SirexeTheme.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ]),

                                const SizedBox(height: 6),
                                Text(
                                  'Hash: ${(b['hashActuel'] as String?)?.substring(0, 20) ?? '—'}...',
                                  style: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                  ),
                                ),

                                if (!ok) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: SirexeTheme.danger.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('⛔ FALSIFICATION DÉTECTÉE',
                                            style: TextStyle(
                                              color: SirexeTheme.danger,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            )),
                                        const SizedBox(height: 4),
                                        Text(b['raisonEchec'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 9,
                                              fontFamily: 'monospace',
                                            )),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ]),
        ),

        Container(width: 0.5, color: SirexeTheme.border),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text('REGISTRE CRYPTOGRAPHIQUE',
                    style: TextStyle(
                      color: SirexeTheme.textSecondary,
                      fontSize: 11,
                      letterSpacing: 1,
                    )),
                const SizedBox(height: 4),
                Text('Vérification SHA-256 de la chaîne d\'intégrité',
                    style: TextStyle(
                      color: SirexeTheme.textSecondary,
                      fontSize: 12,
                    )),

                const SizedBox(height: 24),

                if (_integre != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _integre!
                          ? SirexeTheme.success.withValues(alpha: 0.08)
                          : SirexeTheme.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _integre!
                            ? SirexeTheme.success.withValues(alpha: 0.3)
                            : SirexeTheme.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(children: [
                      Icon(
                        _integre! ? Icons.verified_outlined : Icons.gpp_bad_outlined,
                        size: 32,
                        color: _integre! ? SirexeTheme.success : SirexeTheme.danger,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(_message,
                            style: TextStyle(
                              color: _integre!
                                  ? SirexeTheme.success
                                  : SirexeTheme.danger,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ]),
                  ),

                if (_premierBlocCorrompu != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SirexeTheme.danger.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: SirexeTheme.danger.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.report, color: SirexeTheme.danger, size: 16),
                          const SizedBox(width: 8),
                          Text('PREMIER BLOC CORROMPU — RAPPORT D\'ALERTE',
                              style: TextStyle(
                                color: SirexeTheme.danger,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              )),
                        ]),
                        const SizedBox(height: 16),
                        _ligneDetail('Bloc',
                            '#${_premierBlocCorrompu!['index']}'),
                        _ligneDetail('Opérateur',
                            _premierBlocCorrompu!['operateurNom'] ?? '—'),
                        _ligneDetail('Permis',
                            _premierBlocCorrompu!['permisId'] ?? '—'),
                        _ligneDetail('Heure de détection',
                            _formatDate(_premierBlocCorrompu!['timestamp']?.toString())),
                        _ligneDetail('Poids déclaré',
                            '${(_premierBlocCorrompu!['poidsNetG'] as num).toStringAsFixed(0)} g'),
                        _ligneDetail('Coordonnées',
                            '${_premierBlocCorrompu!['latitude']}, ${_premierBlocCorrompu!['longitude']}'),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 8),
                        Text('HASH ATTENDU',
                            style: TextStyle(
                              color: SirexeTheme.textSecondary,
                              fontSize: 9,
                              letterSpacing: 1,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          _premierBlocCorrompu!['hashAttendu'] ?? '—',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('HASH TROUVÉ',
                            style: TextStyle(
                              color: SirexeTheme.danger,
                              fontSize: 9,
                              letterSpacing: 1,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          _premierBlocCorrompu!['hashPrecedent'] ?? '—',
                          style: TextStyle(
                            color: SirexeTheme.danger.withValues(alpha: 0.8),
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _verifier,
                    icon: _loading
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.link, size: 18),
                    label: Text(_loading
                        ? 'Vérification en cours...'
                        : 'Vérifier l\'intégrité de la chaîne'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SirexeTheme.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),

                Text('[DEV] SIMULATION DE FALSIFICATION',
                    style: TextStyle(
                      color: SirexeTheme.textSecondary.withValues(alpha: 0.4),
                      fontSize: 9,
                      letterSpacing: 1,
                    )),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _falsifier,
                      icon: const Icon(Icons.bug_report, size: 14),
                      label: const Text('Falsifier bloc #4',
                          style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SirexeTheme.danger,
                        side: BorderSide(
                            color: SirexeTheme.danger.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.restore, size: 14),
                      label: const Text('Réinitialiser chaîne',
                          style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SirexeTheme.textSecondary,
                        side: BorderSide(color: SirexeTheme.border),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SirexeTheme.surface1,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: SirexeTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Comment fonctionne la détection',
                          style: const TextStyle(
                            color: SirexeTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 10),
                      ...const [
                        ('1.', 'Chaque pesée génère un hash SHA-256 unique.'),
                        ('2.', 'Ce hash intègre le hash de la pesée précédente.'),
                        ('3.', 'Modifier une pesée brise toute la chaîne.'),
                        ('4.', 'Le serveur détecte qui, quand, et quel bloc.'),
                        ('5.', 'Une alerte fraude est automatiquement créée.'),
                      ].map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 20,
                              child: Text(e.$1,
                                  style: TextStyle(
                                    color: SirexeTheme.accentBlue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ),
                            Expanded(
                              child: Text(e.$2,
                                  style: TextStyle(
                                    color: SirexeTheme.textSecondary,
                                    fontSize: 11,
                                  )),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _ligneDetail(String label, String valeur) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: TextStyle(
                color: SirexeTheme.textSecondary,
                fontSize: 11,
              )),
        ),
        Expanded(
          child: Text(valeur,
              style: const TextStyle(
                color: SirexeTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              )),
        ),
      ],
    ),
  );

  Widget _badge(String label, Color couleur) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: couleur.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: couleur.withValues(alpha: 0.3)),
    ),
    child: Text(label,
        style: TextStyle(
          color: couleur,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        )),
  );
}