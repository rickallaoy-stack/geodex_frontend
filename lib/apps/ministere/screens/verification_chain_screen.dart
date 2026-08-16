import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../../../core/services/verification_service.dart';

class VerificationChainScreen extends StatefulWidget {
  const VerificationChainScreen({super.key});

  @override
  State<VerificationChainScreen> createState() => _VerificationChainScreenState();
}

class _VerificationChainScreenState extends State<VerificationChainScreen> {
  final VerificationService _service = VerificationService();
  Map<String, dynamic>? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.verifierChaine();
      setState(() => _result = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SirexeTheme.background,
      appBar: AppBar(
        backgroundColor: SirexeTheme.surface,
        title: const Text('Vérification chaîne', style: TextStyle(color: SirexeTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: SirexeTheme.textSecondary)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: SirexeTheme.accentBlue))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : _result == null
                  ? const SizedBox.shrink()
                  : _buildBody(),
    );
  }

  Widget _buildBody() {
    final valid = (_result!['valid'] as bool?) ?? false;
    final total = (_result!['total'] as int?) ?? 0;
    final invalid = (_result!['invalid'] as int?) ?? 0;
    final chain = (_result!['chain'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(children: [
      // Header statut
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: valid ? SirexeTheme.accent.withOpacity(0.08) : SirexeTheme.danger.withOpacity(0.08),
          border: Border(bottom: BorderSide(color: valid ? SirexeTheme.accent.withOpacity(0.3) : SirexeTheme.danger.withOpacity(0.3), width: 1)),
        ),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(
            color: valid ? SirexeTheme.accent.withOpacity(0.12) : SirexeTheme.danger.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ), child: Icon(valid ? Icons.verified_rounded : Icons.warning_amber_rounded, color: valid ? SirexeTheme.accent : SirexeTheme.danger, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(valid ? 'Chaîne intègre' : 'Chaîne compromise', style: TextStyle(color: valid ? SirexeTheme.accent : SirexeTheme.danger, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('$total pesée(s) vérifiée(s) · $invalid anomalie(s)', style: const TextStyle(color: SirexeTheme.textSecondary, fontSize: 12)),
          ])),
        ]),
      ),
      Container(height: 0.5, color: SirexeTheme.border),

      // Légende
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: SirexeTheme.surface,
        child: Row(children: [
          _LegendDot(color: SirexeTheme.accent, label: 'Valide'),
          const SizedBox(width: 16),
          _LegendDot(color: SirexeTheme.danger, label: 'Hash invalide'),
          const SizedBox(width: 16),
          _LegendDot(color: SirexeTheme.warning, label: 'Rupture chaîne'),
        ]),
      ),
      Container(height: 0.5, color: SirexeTheme.border),

      // Liste chaîne
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: chain.length,
        itemBuilder: (context, i) => _ChainCard(item: chain[i], index: i),
      )),
    ]);
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.wifi_off_rounded, color: SirexeTheme.danger, size: 48),
    const SizedBox(height: 16),
    Text('Impossible de joindre le backend', style: TextStyle(color: SirexeTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
    const SizedBox(height: 6),
    Text(error, style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 12), textAlign: TextAlign.center),
    const SizedBox(height: 20),
    TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh, color: SirexeTheme.accentBlue), label: const Text('Réessayer', style: TextStyle(color: SirexeTheme.accentBlue))),
  ]));
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(color: SirexeTheme.textSecondary, fontSize: 11)),
  ]);
}

class _ChainCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  const _ChainCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final hashActuel = item['hash_actuel'] as String? ?? '';
    final hashPrecedent = item['hash_precedent'] as String? ?? '';
    final isValid = item['valid'] as bool? ?? false;
    final erreur = item['erreur'] as String? ?? '';
    final id = item['id'] as String? ?? '#$index';

    Color statusColor;
    String statusLabel;
    if (isValid) {
      statusColor = SirexeTheme.accent;
      statusLabel = 'Valide';
    } else if (erreur.contains('hash') || erreur.contains('Hash')) {
      statusColor = SirexeTheme.danger;
      statusLabel = 'Hash invalide';
    } else {
      statusColor = SirexeTheme.warning;
      statusLabel = 'Rupture';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SirexeTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isValid ? SirexeTheme.accent.withOpacity(0.2) : SirexeTheme.danger.withOpacity(0.3), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ), child: Icon(isValid ? Icons.check_circle_outline : Icons.warning_amber_rounded, color: statusColor, size: 16)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(id, style: const TextStyle(color: SirexeTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500)),
          ])),
          if (!isValid && erreur.isNotEmpty)
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(
              color: SirexeTheme.danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: SirexeTheme.danger.withOpacity(0.25)),
            ), child: Text(erreur, style: const TextStyle(color: SirexeTheme.danger, fontSize: 10))),
        ]),
        const SizedBox(height: 10),
        _HashRow(label: 'Hash actuel', value: hashActuel, isValid: isValid),
        const SizedBox(height: 6),
        _HashRow(label: 'Hash précédent', value: hashPrecedent, isValid: isValid),
      ]),
    );
  }
}

class _HashRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isValid;
  const _HashRow({required this.label, required this.value, required this.isValid});

  @override
  Widget build(BuildContext context) {
    final display = value.isEmpty ? '—' : '${value.substring(0, 16)}...';
    return Row(children: [
      SizedBox(width: 100, child: Text(label, style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 11))),
      Expanded(child: GestureDetector(
        onTap: value.isEmpty ? null : () => Clipboard.setData(ClipboardData(text: value)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: SirexeTheme.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: SirexeTheme.border),
          ),
          child: Row(children: [
            Expanded(child: Text(display, style: const TextStyle(color: SirexeTheme.textPrimary, fontSize: 11, fontFamily: 'monospace', letterSpacing: 0.3))),
            if (value.isNotEmpty) Icon(Icons.copy, color: SirexeTheme.textSecondary, size: 13),
          ]),
        ),
      )),
    ]);
  }
}
