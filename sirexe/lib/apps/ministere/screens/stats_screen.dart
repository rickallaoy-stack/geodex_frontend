import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/services/pesee_service.dart';
import '../../../core/services/permis_service.dart';
import '../../../models/permis_minier.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _loading = true;

  int    _totalPermis      = 0;
  int    _permisActifs     = 0;
  int    _permisSupendus   = 0;
  int    _permisRevoques   = 0;
  int    _totalAlertes     = 0;
  double _tonnageTotalKg   = 0;
  double _taxesEstimeees   = 0;
  Map<String, double> _tonnageParMinerai = {};
  Map<String, int>    _alertesParType    = {};
  List<_SiteStat>     _topSites          = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final pesees  = await PeseeService.fetchPesees();
    final alertes = await PeseeService.fetchAlertes();
    final permis  = await PermisService.fetchPermis();

    final actifs    = permis.where((p) => p.statut == StatutPermis.valide).length;
    final suspendus = permis.where((p) => p.statut == StatutPermis.suspendu).length;
    final revoques  = permis.where((p) => p.statut == StatutPermis.revoque).length;

    double tonnage = 0;
    final Map<String, double> parMinerai = {};
    final Map<String, double> parSite    = {};

    for (final p in pesees) {
      final kg      = (p['poids_mesure_kg'] ?? 0).toDouble();
      final minerai = (p['minerai'] ?? 'AUTRE').toString();
      final permisId = (p['code_permis'] ?? 'Inconnu').toString();

      tonnage += kg;
      parMinerai[minerai] = (parMinerai[minerai] ?? 0) + kg;
      parSite[permisId]   = (parSite[permisId] ?? 0) + kg;
    }

    final taxesOr    = (parMinerai['OR']    ?? 0) * 0.03 * 60000;
    final taxesAutre = (parMinerai.entries
      .where((e) => e.key != 'OR')
      .fold(0.0, (s, e) => s + e.value)) * 0.03 * 5000;
    final taxes = taxesOr + taxesAutre;

    final Map<String, int> parType = {};
    for (final a in alertes) {
      parType[a.typeAnomalie] = (parType[a.typeAnomalie] ?? 0) + 1;
    }

    final topSites = parSite.entries
      .map((e) => _SiteStat(nom: e.key, tonnageKg: e.value))
      .toList()
      ..sort((a, b) => b.tonnageKg.compareTo(a.tonnageKg));

    setState(() {
      _totalPermis       = permis.length;
      _permisActifs      = actifs;
      _permisSupendus    = suspendus;
      _permisRevoques    = revoques;
      _totalAlertes      = alertes.length;
      _tonnageTotalKg    = tonnage;
      _taxesEstimeees    = taxes;
      _tonnageParMinerai = parMinerai;
      _alertesParType    = parType;
      _topSites          = topSites.take(5).toList();
      _loading           = false;
    });
  }

  String _formatFcfa(double v) {
    if (v >= 1e9)  return '${(v / 1e9).toStringAsFixed(1)} Mds FCFA';
    if (v >= 1e6)  return '${(v / 1e6).toStringAsFixed(1)} M FCFA';
    if (v >= 1e3)  return '${(v / 1e3).toStringAsFixed(0)} K FCFA';
    return '${v.toStringAsFixed(0)} FCFA';
  }

  String _formatTonne(double kg) {
    if (kg >= 1000) return '${(kg / 1000).toStringAsFixed(2)} t';
    return '${kg.toStringAsFixed(1)} kg';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(
      child: CircularProgressIndicator(
        color: SirexeTheme.accentBlue, strokeWidth: 2));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Indicateurs clés'),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _KpiCard(
              label:  'Permis actifs',
              value:  '$_permisActifs / $_totalPermis',
              icon:   Icons.verified_outlined,
              color:  SirexeTheme.accent),
            _KpiCard(
              label:  'Tonnage total extrait',
              value:  _formatTonne(_tonnageTotalKg),
              icon:   Icons.scale_outlined,
              color:  SirexeTheme.accentBlue),
            _KpiCard(
              label:  'Taxes estimées collectées',
              value:  _formatFcfa(_taxesEstimeees),
              icon:   Icons.account_balance_outlined,
              color:  const Color(0xFF8B5CF6)),
            _KpiCard(
              label:  'Alertes fraude',
              value:  '$_totalAlertes',
              icon:   Icons.warning_amber_rounded,
              color:  SirexeTheme.danger),
            _KpiCard(
              label:  'Permis suspendus',
              value:  '$_permisSupendus',
              icon:   Icons.pause_circle_outline,
              color:  SirexeTheme.warning),
            _KpiCard(
              label:  'Permis révoqués',
              value:  '$_permisRevoques',
              icon:   Icons.cancel_outlined,
              color:  SirexeTheme.textSecondary),
          ]),
          const SizedBox(height: 28),

          if (_tonnageParMinerai.isNotEmpty) ...[
            _sectionTitle('Tonnage par minerai'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SirexeTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SirexeTheme.border)),
              child: Column(
                children: _tonnageParMinerai.entries.map((e) {
                  final pct = _tonnageTotalKg > 0
                    ? e.value / _tonnageTotalKg : 0.0;
                  final color = _mineraiColor(e.key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(children: [
                      Row(children: [
                        Container(width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(e.key, style: const TextStyle(
                          color: SirexeTheme.textPrimary, fontSize: 12)),
                        const Spacer(),
                        Text(_formatTonne(e.value), style: const TextStyle(
                          color: SirexeTheme.textPrimary,
                          fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Text('${(pct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: SirexeTheme.textSecondary, fontSize: 11)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: SirexeTheme.surfaceElevated,
                          color: color,
                          minHeight: 6)),
                    ]),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),
          ],

          if (_topSites.isNotEmpty) ...[
            _sectionTitle('Top sites par tonnage extrait'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: SirexeTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SirexeTheme.border)),
              child: Column(
                children: _topSites.asMap().entries.map((e) {
                  final i    = e.key;
                  final site = e.value;
                  final pct  = _tonnageTotalKg > 0
                    ? site.tonnageKg / _tonnageTotalKg : 0.0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(
                        color: i == 0
                          ? Colors.transparent : SirexeTheme.border,
                        width: 0.5))),
                    child: Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: SirexeTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(6)),
                        child: Center(child: Text('${i + 1}',
                          style: const TextStyle(
                            color: SirexeTheme.textSecondary,
                            fontSize: 12, fontWeight: FontWeight.w700)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(site.nom, style: const TextStyle(
                            color: SirexeTheme.textPrimary,
                            fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: SirexeTheme.surfaceElevated,
                              color: SirexeTheme.accentBlue,
                              minHeight: 4)),
                        ],
                      )),
                      const SizedBox(width: 12),
                      Text(_formatTonne(site.tonnageKg),
                        style: const TextStyle(
                          color: SirexeTheme.textPrimary,
                          fontSize: 13, fontWeight: FontWeight.w700)),
                    ]),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),
          ],

          if (_alertesParType.isNotEmpty) ...[
            _sectionTitle('Répartition des alertes'),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10,
              children: _alertesParType.entries.map((e) =>
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: SirexeTheme.danger.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SirexeTheme.danger.withOpacity(0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.warning_amber_rounded,
                      color: SirexeTheme.danger, size: 14),
                    const SizedBox(width: 7),
                    Text(e.key, style: const TextStyle(
                      color: SirexeTheme.textSecondary, fontSize: 12)),
                    const SizedBox(width: 7),
                    Text('${e.value}', style: const TextStyle(
                      color: SirexeTheme.danger,
                      fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                )
              ).toList(),
            ),
            const SizedBox(height: 28),
          ],

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SirexeTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SirexeTheme.border)),
            child: const Row(children: [
              Icon(Icons.info_outline,
                color: SirexeTheme.textSecondary, size: 14),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Taxes estimées à titre indicatif (3% du tonnage × prix marché).'
                ' Données issues du registre cryptographique GEODEX.',
                style: TextStyle(
                  color: SirexeTheme.textSecondary, fontSize: 11))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(
    color: SirexeTheme.textSecondary, fontSize: 11,
    fontWeight: FontWeight.w500, letterSpacing: 1,
    decoration: TextDecoration.none));

  Color _mineraiColor(String m) {
    switch (m) {
      case 'OR':       return const Color(0xFFD29922);
      case 'DIAMANT':  return const Color(0xFF1F6FEB);
      case 'NICKEL':   return const Color(0xFF238636);
      case 'MANGANESE':return const Color(0xFF8B5CF6);
      case 'BAUXITE':  return const Color(0xFFE8704A);
      default:         return const Color(0xFF8B949E);
    }
  }
}

class _SiteStat {
  final String nom;
  final double tonnageKg;
  const _SiteStat({required this.nom, required this.tonnageKg});
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _KpiCard({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 180,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: SirexeTheme.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: SirexeTheme.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(7)),
          child: Icon(icon, color: color, size: 15)),
        const Spacer(),
      ]),
      const SizedBox(height: 12),
      Text(value, style: TextStyle(
        color: color, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(
        color: SirexeTheme.textSecondary, fontSize: 11)),
    ]),
  );
}
