import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/theme.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/pesee_service.dart';
import '../../../models/investigation_operateur.dart';

class InvestigationScreen extends StatefulWidget {
  const InvestigationScreen({super.key});
  @override
  State<InvestigationScreen> createState() => _InvestigationScreenState();
}

class _InvestigationScreenState extends State<InvestigationScreen> {
  final String _base = ApiConfig.baseUrl;
  final TextEditingController _searchCtrl = TextEditingController();

  List<OperateurInvestigable> _operateurs = [];
  List<AlerteBackend> _alertes = [];
  List<Map<String, dynamic>> _pesees = [];
  bool _loading = true;
  String? _erreur;

  TypeExploitant _filtreType = TypeExploitant.tous;
  OperateurInvestigable? _selection;

  @override
  void initState() {
    super.initState();
    _chargerTout();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerTout() async {
    setState(() => _loading = true);
    try {
      final opsSnap = await http.get(
        Uri.parse('$_base/api/pesees/bornes/activite'),
      ).timeout(const Duration(seconds: 8));

      if (opsSnap.statusCode == 200) {
        final data = jsonDecode(opsSnap.body) as Map<String, dynamic>;
        final liste = (data['operateurs'] as List)
            .map((e) => OperateurInvestigable.fromJson(e as Map<String, dynamic>))
            .toList();

        final alertesSnap = await http.get(
          Uri.parse('$_base/api/pesees/alertes'),
        ).timeout(const Duration(seconds: 8));

        final peseesSnap = await http.get(
          Uri.parse('$_base/api/pesees'),
        ).timeout(const Duration(seconds: 8));

        List<AlerteBackend> alertes = [];
        if (alertesSnap.statusCode == 200) {
          final ab = jsonDecode(alertesSnap.body) as Map<String, dynamic>;
          alertes = (ab['data'] as List)
              .map((e) => AlerteBackend.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        List<Map<String, dynamic>> pesees = [];
        if (peseesSnap.statusCode == 200) {
          final pb = jsonDecode(peseesSnap.body) as Map<String, dynamic>;
          pesees = List<Map<String,dynamic>>.from(pb['data'] as List);
        }

        if (!mounted) return;
        setState(() {
          _operateurs = liste;
          _alertes = alertes;
          _pesees = pesees;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _erreur = 'Erreur serveur (${opsSnap.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = 'Serveur inaccessible');
    }
  }

  List<OperateurInvestigable> get _operateursFiltres {
    var list = _operateurs;
    if (_filtreType != TypeExploitant.tous) {
      list = list.where((o) => o.type == _filtreType).toList();
    }
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isNotEmpty) {
      list = list.where((o) =>
        o.nom.toLowerCase().contains(q) ||
        o.permisId.toLowerCase().contains(q) ||
        o.entreprise.toLowerCase().contains(q) ||
        o.minerai.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  List<AlerteBackend> get _alertesDuOperateur {
    if (_selection == null) return [];
    return _alertes.where((a) =>
      (a.operateurNom != null && a.operateurNom!.toLowerCase().contains(_selection!.nom.toLowerCase())) ||
      (a.permisNumero != null && a.permisNumero!.toLowerCase().contains(_selection!.permisId.toLowerCase())) ||
      (a.permisNumero != null && a.permisNumero!.toLowerCase().contains(_selection!.permisId.toLowerCase()))
    ).toList();
  }

  List<Map<String, dynamic>> get _peseesDuOperateur {
    if (_selection == null) return [];
    return _pesees.where((p) =>
      (p['code_permis'] as String? ?? '') == _selection!.permisId
    ).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SirexeTheme.surfaceLevel0,
    body: _loading
      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
      : _erreur != null
        ? Center(child: Text(_erreur!, style: TextStyle(color: SirexeTheme.danger)))
        : LayoutBuilder(
            builder: (context, constraints) {
              final large = constraints.maxWidth >= 1000;
              return Row(children: [
                SizedBox(
                  width: large ? 380 : 240,
                  child: _leftPanel(),
                ),
                Container(width: 1, color: SirexeTheme.border),
                Expanded(child: large ? _rightPanel() : _rightPanel()),
              ]);
            }),
  );

  Widget _leftPanel() => Column(children: [
    _header(),
    const SizedBox(height: 12),
    _filtresType(),
    Expanded(child: _listeOperateurs()),
  ]);

  Widget _header() => Padding(
    padding: const EdgeInsets.all(20),
    child: Row(children: [
      Expanded(child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: SirexeTheme.surfaceLevel1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SirexeTheme.border),
        ),
        child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Rechercher nom / permis / site / type...',
            hintStyle: TextStyle(color: SirexeTheme.textSecondary, fontSize: 12),
            prefixIcon: Icon(Icons.search, color: SirexeTheme.textSecondary, size: 18),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          style: TextStyle(color: SirexeTheme.textPrimary, fontSize: 13),
          onChanged: (_) => setState(() {}),
        ),
      )),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: SirexeTheme.danger.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SirexeTheme.danger.withOpacity(0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
          const SizedBox(width: 4),
          Text('${_alertes.length} alertes', style: TextStyle(color: SirexeTheme.danger, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    ]),
  );

  Widget _filtresType() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: SirexeTheme.border, width: 0.5))),
    child: Wrap(spacing: 8, runSpacing: 6, children: [
      for (final t in TypeExploitant.values)
        _filterChip(t),
    ]),
  );

  Widget _filterChip(TypeExploitant t) => ChoiceChip(
    label: Row(children: [
      Icon(t.icone, size: 14, color: t == _filtreType ? Colors.white : t.couleur),
      const SizedBox(width: 4),
      Text(t.label, style: TextStyle(
        color: t == _filtreType ? Colors.white : Colors.white70,
        fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
    selected: _filtreType == t,
    onSelected: (_) => setState(() => _filtreType = t),
    backgroundColor: SirexeTheme.surfaceLevel1,
    selectedColor: t.couleur.withOpacity(0.3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  );

  Widget _listeOperateurs() => _operateursFiltres.isEmpty
    ? const Center(child: Text('Aucun opérateur trouvé', style: TextStyle(color: Colors.white60)))
    : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _operateursFiltres.length,
        itemBuilder: (_, i) {
          final op = _operateursFiltres[i];
          final selected = _selection?.id == op.id;
          return _operateurCard(op, selected);
        },
      );

  Widget _operateurCard(OperateurInvestigable op, bool selected) {
    final couleur = op.quotaDepasse ? Colors.redAccent
      : op.type.couleur;
    final ratio = op.quotaJourKg > 0
      ? (op.quotaJourConsommeKg / op.quotaJourKg).clamp(0.0, 1.0)
      : 0.0;
    final consommeStr = '${op.quotaJourConsommeKg.toStringAsFixed(0)} / ${op.quotaJourKg.toStringAsFixed(0)}g';

    return GestureDetector(
      onTap: () => setState(() => _selection = op),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
            ? SirexeTheme.surfaceLevel2
            : SirexeTheme.surfaceLevel1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected
            ? couleur.withOpacity(0.5)
            : SirexeTheme.border, width: selected ? 1.5 : 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 14, backgroundColor: couleur.withOpacity(0.2), child: Icon(op.type.icone, color: couleur, size: 14)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(op.nom, style: TextStyle(color: SirexeTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${op.permisId} · ${op.minerai}', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 10)),
            ])),
            Text(op.permisStatut, style: TextStyle(color: _statutColor(op.permisStatut), fontSize: 10, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: ratio, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(couleur), minHeight: 4, borderRadius: BorderRadius.circular(2)),
          const SizedBox(height: 2),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(consommeStr, style: TextStyle(color: couleur, fontSize: 10)),
            if (op.quotaDepasse) const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 14),
          ]),
        ]),
      ),
    );
  }

  Color _statutColor(String statut) {
    switch (statut.toUpperCase()) {
      case 'VALIDE':     return SirexeTheme.success;
      case 'SUSPENDU':   return SirexeTheme.warning;
      case 'REVOQUE':    return SirexeTheme.danger;
      case 'EN_ATTENTE': return SirexeTheme.textSecondary;
      default:           return SirexeTheme.textSecondary;
    }
  }

  Widget _rightPanel() {
    if (_selection == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.person_search, size: 64, color: Colors.white24),
          const SizedBox(height: 12),
          Text('Sélectionnez un opérateur', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 14)),
          Text('Cliquez sur une ligne pour voir le détail.', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 11)),
        ]),
      );
    }

    final op = _selection!;
    final ratioJ = op.quotaJourKg > 0 ? (op.quotaJourConsommeKg / op.quotaJourKg).clamp(0.0, 1.0) : 0.0;
    final ratioM = op.quotaMensuelKg > 0 ? (op.quotaMensuelConsommeKg / op.quotaMensuelKg).clamp(0.0, 1.0) : 0.0;
    final couleurQuota = op.quotaDepasse ? Colors.redAccent
      : ratioJ > 0.9 ? Colors.orange
      : SirexeTheme.success;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _detailHeader(op),
        const SizedBox(height: 24),
        _quotasSection(op, ratioJ, ratioM, couleurQuota),
        const SizedBox(height: 24),
        _historiqueSection(),
        const SizedBox(height: 24),
        _alertesSection(),
      ]),
    );
  }

  Widget _detailHeader(OperateurInvestigable op) => Row(children: [
    Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: op.type.couleur.withOpacity(0.15), border: Border.all(color: op.type.couleur.withOpacity(0.4))), child: Icon(op.type.icone, color: op.type.couleur, size: 28)),
    const SizedBox(width: 16),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(op.nom, style: TextStyle(color: SirexeTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('${op.permisId} · ${op.type.label}', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 13)),
      const SizedBox(height: 2),
      Text('${op.entreprise} · Site: ${_siteNom(op)}', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 12)),
    ])),
    IconButton(icon: Icon(Icons.print_outlined, color: SirexeTheme.textSecondary, size: 20), onPressed: () {}),
  ]);

  String _siteNom(OperateurInvestigable op) => op.permisId.contains('CI-2019') ? 'Tongon'
    : op.permisId.contains('CI-2021-088') ? 'Séguéla'
    : op.permisId.contains('CI-2014') ? 'Agbaou'
    : 'Inconnu';

  Widget _quotasSection(OperateurInvestigable op, double ratioJ, double ratioM, Color couleur) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: SirexeTheme.surfaceLevel1, borderRadius: BorderRadius.circular(12), border: Border.all(color: SirexeTheme.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('QUOTAS', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
      const SizedBox(height: 16),
      _quotaBar('Jour', '${op.quotaJourConsommeKg.toStringAsFixed(0)} / ${op.quotaJourKg.toStringAsFixed(0)}g', ratioJ, couleur, '${op.quotaJourRestant.toStringAsFixed(0)} g restants'),
      const SizedBox(height: 16),
      _quotaBar('Mois', '${op.quotaMensuelConsommeKg.toStringAsFixed(0)} / ${op.quotaMensuelKg.toStringAsFixed(0)}g', ratioM, couleur, '${op.quotaMensuelRestant.toStringAsFixed(0)} g restants'),
    ]),
  );

  Widget _quotaBar(String label, String valeur, double ratio, Color couleur, String restant) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 11)),
      Text(valeur, style: TextStyle(color: couleur, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
    const SizedBox(height: 6),
    LinearProgressIndicator(value: ratio, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(couleur), minHeight: 8, borderRadius: BorderRadius.circular(4)),
    const SizedBox(height: 4),
    Text(restant, style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 10)),
  ]);

  Widget _historiqueSection() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('HISTORIQUE DES PESÉES', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
    const SizedBox(height: 10),
    _peseesDuOperateur.isEmpty
      ? _emptySub('Aucune pesée enregistrée')
      : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _peseesDuOperateur.length,
          itemBuilder: (_, i) {
            final p = _peseesDuOperateur[i];
            final statut = p['statut'] ?? 'INCONNU';
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: SirexeTheme.border, width: 0.5))),
              child: Row(children: [
                Text(_dateCourt(p['date_releve']), style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 11)),
                const SizedBox(width: 12),
                Text('${(p['poids_mesure_kg'] as num).toStringAsFixed(2)} g', style: TextStyle(color: SirexeTheme.textPrimary, fontSize: 12)),
                const SizedBox(width: 12),
                Text(p['capteur_id'] ?? '', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 11)),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _statutColor(statut).withOpacity(0.15), borderRadius: BorderRadius.circular(4)), child: Text(statut, style: TextStyle(color: _statutColor(statut), fontSize: 10, fontWeight: FontWeight.w600))),
              ]),
            );
          },
        ),
  ]);

  Widget _alertesSection() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('ALERTES LIÉES', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
    const SizedBox(height: 10),
    _alertesDuOperateur.isEmpty
      ? _emptySub('Aucune alerte')
      : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _alertesDuOperateur.length,
          itemBuilder: (_, i) {
            final a = _alertesDuOperateur[i];
            final couleur = a.typeAnomalie.contains('HORS_ZONE') || a.typeAnomalie.contains('PERMIS_EXPIRE')
              ? SirexeTheme.danger : SirexeTheme.warning;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: SirexeTheme.border, width: 0.5))),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded, color: couleur, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.typeLabel, style: TextStyle(color: SirexeTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(a.description, style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                ])),
                Text(_dateCourtCourt(a.dateAlerte), style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 10)),
              ]),
            );
          },
        ),
  ]);

  Widget _emptySub(String msg) => Center(
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text(msg, style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 12))),
  );

  String _dateCourt(dynamic raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  String _dateCourtCourt(DateTime dt) => '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}';
}
