import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geodex/core/theme.dart';
import 'package:geodex/core/config/api_config.dart';

class BorneActiviteWidget extends StatefulWidget {
  const BorneActiviteWidget({super.key});

  @override
  State<BorneActiviteWidget> createState() => _BorneActiviteWidgetState();
}

class _BorneActiviteWidgetState extends State<BorneActiviteWidget> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _erreur = null; });
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/pesees/bornes/activite'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        setState(() { _data = jsonDecode(res.body); _loading = false; });
      } else {
        setState(() { _erreur = 'Erreur serveur'; _loading = false; });
      }
    } catch (_) {
      setState(() { _erreur = 'Serveur inaccessible'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SirexeTheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ACTIVITE BORNES",
                style: TextStyle(
                  color: SirexeTheme.success,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white38),
                onPressed: _charger,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (_erreur != null)
            Text(_erreur!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))
          else ...[
            _buildStats(),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),
            ...((_data!['operateurs'] as List).map(_buildLigneOperateur)),
          ],
        ],
      ),
    );
  }

  Widget _buildStats() {
    final s = _data!['stats'];
    return Row(
      children: [
        _stat('Operateurs', '${s['totalOperateurs']}', SirexeTheme.success),
        const SizedBox(width: 24),
        _stat('Kg jour total', '${(s['totalKgJour'] as num).toStringAsFixed(0)} g', Colors.white70),
        const SizedBox(width: 24),
        _stat('Quotas depasses', '${s['quotasDepasses']}',
            s['quotasDepasses'] > 0 ? Colors.redAccent : Colors.white38),
      ],
    );
  }

  Widget _stat(String label, String valeur, Color couleur) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      const SizedBox(height: 2),
      Text(valeur, style: TextStyle(color: couleur, fontSize: 18, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildLigneOperateur(dynamic op) {
    final consomme = (op['consommeJourKg'] as num?)?.toDouble() ?? 0;
    final total    = (op['quotaJourKg'] as num?)?.toDouble() ?? 1;
    final restant  = (op['quotaJourRestantKg'] as num?)?.toDouble() ?? 0;
    final nbPesees = op['nbPeseesJour'] as int? ?? 0;
    final depasse  = op['quotaDepasse'] as bool? ?? false;
    final ratio    = (consomme / total).clamp(0.0, 1.0);

    final couleur = depasse
        ? Colors.redAccent
        : ratio > 0.7
            ? SirexeTheme.warning
            : SirexeTheme.success;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(op['nom'] ?? '—',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              Row(children: [
                Text('$nbPesees pesée${nbPesees > 1 ? 's' : ''}',
                    style: TextStyle(
                        color: SirexeTheme.textSecondary, fontSize: 10)),
                const SizedBox(width: 10),
                Text(
                  depasse
                      ? '⛔ Quota dépassé'
                      : '${(consomme * 1000).toStringAsFixed(0)} / ${(total * 1000).toStringAsFixed(0)} g',
                  style: TextStyle(color: couleur, fontSize: 11),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(couleur),
              minHeight: 4,
            ),
          ),
          if (op['dernierePesee'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Dernière pesée : ${_formatDate(op['dernierePesee'])}',
              style: TextStyle(
                  color: SirexeTheme.textSecondary.withValues(alpha: 0.5),
                  fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
